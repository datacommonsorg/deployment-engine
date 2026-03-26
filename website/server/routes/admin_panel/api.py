# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from datetime import datetime
import fcntl
import hmac
from io import BytesIO
import json
import logging
import os
import subprocess
import threading

from flask import Blueprint
from flask import request
from flask import session
from google.cloud import storage
import server.lib.config as lib_config
from shared.lib.gcs import get_path_parts
from shared.lib.gcs import is_gcs_path
from werkzeug.utils import secure_filename

from .constants import ADMIN_PANEL_PASSWORD
from .constants import ADMIN_PANEL_USERNAME
from .constants import BUCKET_BLOB_DOMAIN_CONFIG_LOC
from .constants import BUCKET_BLOB_DOMAIN_LOGO_LOC
from .constants import INPUT_DIR
from .utils import delete_file_from_storage
from .utils import file_exists_in_storage
from .utils import get_blob_location
from .utils import require_login
from .utils import upload_file_to_storage
from .validate import validate_csv

bp = Blueprint('admin_panel_api', __name__, url_prefix='/admin/api')

_STATE_FILE = '/tmp/db_embeddings_state.json'
_DEFAULT_STATE = {
    'status': 'idle',
    'error': None,
    'started_at': None,
    'finished_at': None,
}


def _read_state() -> dict:
  """Read the db-embeddings state from the shared file, with a shared lock."""
  try:
    with open(_STATE_FILE, 'r') as f:
      fcntl.flock(f, fcntl.LOCK_SH)
      try:
        return json.load(f)
      finally:
        fcntl.flock(f, fcntl.LOCK_UN)
  except FileNotFoundError:
    return dict(_DEFAULT_STATE)
  except Exception:
    logging.warning('Failed to read db-embeddings state file', exc_info=True)
    return dict(_DEFAULT_STATE)


def _write_state(state: dict) -> None:
  """Write the db-embeddings state to the shared file, with an exclusive lock."""
  try:
    with open(_STATE_FILE, 'w') as f:
      fcntl.flock(f, fcntl.LOCK_EX)
      try:
        json.dump(state, f)
      finally:
        fcntl.flock(f, fcntl.LOCK_UN)
  except Exception:
    logging.error('Failed to write db-embeddings state file', exc_info=True)


def _monitor_db_embeddings(proc):
  stdout, _ = proc.communicate()
  output = stdout or ''
  state = _read_state()
  state['finished_at'] = datetime.utcnow().isoformat() + 'Z'
  if proc.returncode != 0:
    last_line = output.splitlines()[-1] if output.strip() else 'Unknown error'
    state['status'] = 'failed'
    state['error'] = last_line
    logging.error(f'DB-sync and embeddings build failed (exit {proc.returncode}):\n{output}')
  else:
    state['status'] = 'completed'
    state['error'] = None
    logging.info(f'DB-sync and embeddings build completed:\n{output}')
  _write_state(state)


def allowed_file(filename, extensions):
  """Check if file extension is allowed"""
  return '.' in filename and filename.rsplit('.', 1)[1].lower() in extensions


@bp.route('/login', methods=['POST'])
def login():
  # Prevention authorizing when credentials were not set.
  if not all([ADMIN_PANEL_USERNAME, ADMIN_PANEL_PASSWORD]):
    logging.warning('Admin credentials were not configured')

    return {
        'category': 'error',
        'message': 'Login failed. Please check your credentials.'
    }, 400

  username = request.form.get('username')
  password = request.form.get('password')

  # Validate credentials
  if username == ADMIN_PANEL_USERNAME and hmac.compare_digest(password, ADMIN_PANEL_PASSWORD):
    # Create permanent session with expiration
    session.permanent = True
    session['username'] = username
    session['login_time'] = datetime.now().isoformat()
    session['ip_address'] = request.remote_addr

    return {'category': 'success', 'message': 'OK'}, 200
  else:
    return {
        'category': 'error',
        'message': 'Login failed. Please check your credentials.'
    }, 400


@bp.route('/logout', methods=['POST'])
@require_login
def logout():
  """Logout user"""
  session.clear()
  return {'category': 'success', 'message': 'OK'}, 200


def _resolve_upload_filename(original_filename, base_filename,
                             replace_file_mode):
  """Determine the storage filename for an upload.

  When base_filename is provided (legacy mode), the behaviour depends on
  replace_file_mode: replace keeps the exact name, otherwise a timestamped
  composite name is generated.  When base_filename is absent the original
  filename is preserved via secure_filename.
  """
  if not base_filename:
    return secure_filename(original_filename)
  if replace_file_mode:
    return base_filename
  timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
  return f'{timestamp}__{secure_filename(original_filename)}__{base_filename}'


@bp.route('/upload', methods=['POST'])
@require_login
def upload_file():
  """Handle file upload"""
  cfg = lib_config.get_config()

  if 'file' not in request.files:
    return {'category': 'error', 'message': 'No file part in request'}, 400

  file = request.files['file']

  base_filename = request.form.get('baseFilename')
  replace_file_mode = request.form.get('replaceFileMode', False)

  if not file.filename:
    return {'category': 'error', 'message': 'No file selected'}, 400

  filename = _resolve_upload_filename(file.filename, base_filename,
                                      replace_file_mode)

  if file and allowed_file(file.filename, cfg.ALLOWED_DATA_EXTENSIONS):
    try:
      validation_result = validate_csv(file,
                                       cfg.CSV_SCHEMAS.get(base_filename or filename, {}))
    except Exception as e:
      logging.error(f'Error during file validation {e!r}')
      return {
          'category': 'error',
          'message': 'Error during file validation',
      }, 400

    # Fail if any row has validation errors
    if not validation_result.is_valid:
      return {
          'category':
              'error',
          'message':
              f'File validation failed: {validation_result.invalid_rows_count} row(s) have errors',
          'validation_errors': [
              f"Row {row}, Column {col}: {msg}"
              for row, col, msg in validation_result.errors
          ],
          **validation_result.response_info
      }, 400

    # Reset file pointer after validation
    validation_result.valid_csv.seek(0)

    try:
      blob_location = get_blob_location(filename)
      upload_file_to_storage(INPUT_DIR, blob_location,
                             validation_result.valid_csv)

      return {
          'category': 'success',
          'message': f'File "{file.filename}" uploaded successfully!',
          **validation_result.response_info
      }, 200

    except Exception as e:
      logging.error(f'Error during uploading file {e!r}')
      return {
          'category': 'error',
          'message': 'Error during uploading file',
          **validation_result.response_info
      }, 400
  else:
    return {
        'category':
            'error',
        'message':
            f'File type not allowed. Allowed types: {", ".join(cfg.ALLOWED_DATA_EXTENSIONS)}'
    }, 400


@bp.route('/upload-config', methods=['POST'])
@require_login
def upload_config_file():
  """Handle config.json and stat_vars.mcf uploads"""
  cfg = lib_config.get_config()

  if 'file' not in request.files:
    return {'category': 'error', 'message': 'No file part in request'}, 400

  file = request.files['file']

  if not file.filename:
    return {'category': 'error', 'message': 'No file selected'}, 400

  filename = secure_filename(file.filename)

  if filename not in cfg.ALLOWED_CONFIG_FILENAMES:
    return {
        'category':
            'error',
        'message':
            f'Only {", ".join(sorted(cfg.ALLOWED_CONFIG_FILENAMES))} files are allowed'
    }, 400

  if filename.endswith('.json'):
    try:
      content = file.read()
      json.loads(content)
      file.seek(0)
    except json.JSONDecodeError as e:
      return {
          'category': 'error',
          'message': f'Invalid JSON: {str(e)}'
      }, 400

  try:
    blob_location = get_blob_location(filename)
    upload_file_to_storage(INPUT_DIR, blob_location, file)

    return {
        'category': 'success',
        'message': f'File "{filename}" uploaded successfully!'
    }, 200

  except Exception as e:
    logging.error(f'Error during uploading file {e!r}')
    return {
        'category': 'error',
        'message': 'Error during uploading file',
    }, 400


@bp.route('/update-config', methods=['POST'])
@require_login
def update_config():
  cfg = lib_config.get_config()

  default_config = getattr(cfg, 'DEFAULT_DOMAIN_CONFIG', {})
  new_config = {}
  for k in default_config.keys():
    new_config[k] = request.form.get(k, default_config[k])

  new_config_file = BytesIO()
  new_config_file.write(json.dumps(new_config).encode())
  new_config_file.seek(0)

  # Main config upload
  message = "Domain config updated"
  try:
    upload_file_to_storage(INPUT_DIR, BUCKET_BLOB_DOMAIN_CONFIG_LOC,
                           new_config_file)
  except Exception as e:
    logging.error(f'Config uploading failed with {e!r}')
    return {'category': 'error', 'message': 'Config uploading failed'}, 400

  try:
    # Logo upload or deletion
    file = request.files.get('file')

    # If logoPresent is "false" and no new file uploaded, delete existing logo
    if new_config.get('logoPresent') == 'false' and not file:
      if delete_file_from_storage(INPUT_DIR, BUCKET_BLOB_DOMAIN_LOGO_LOC):
        message = "Domain config updated and logo removed"
    elif file and allowed_file(file.filename, cfg.ALLOWED_LOGO_EXTENSIONS):
      upload_file_to_storage(INPUT_DIR, BUCKET_BLOB_DOMAIN_LOGO_LOC, file)
      message = "Domain config and domain logo updated"
  except Exception as e:
    logging.error(f'Logo operation failed with {e!r}')
    return {'category': 'success', 'message': 'Logo operation failed'}, 400

  return {'category': 'success', 'message': message}, 200


@bp.route('/domain-config', methods=['GET'])
def domain_config():
  cfg = lib_config.get_config()
  default_config = getattr(cfg, 'DEFAULT_DOMAIN_CONFIG', {})

  if is_gcs_path(INPUT_DIR):
    client = storage.Client()

    bucket_name, _ = get_path_parts(INPUT_DIR)

    bucket = client.bucket(bucket_name)
    blob = bucket.get_blob(BUCKET_BLOB_DOMAIN_CONFIG_LOC)

    if not blob:
      return default_config

    return json.loads(blob.download_as_bytes())
  else:
    local_base_folder_loc = INPUT_DIR.rsplit('/', 1)[0]
    filepath = os.path.join(local_base_folder_loc,
                            BUCKET_BLOB_DOMAIN_CONFIG_LOC)

    if not os.path.exists(filepath):
      return default_config

    with open(filepath) as f:
      return json.load(f)


@bp.route('/run-db-sync-and-embeddings-build', methods=['POST'])
@require_login
def run_db_sync_and_embeddings_build():
  """Start the db-sync and embeddings build as a background process."""
  if _read_state()['status'] == 'running':
    return {
        'category': 'error',
        'message': 'DB-sync and embeddings build is already running',
    }, 409

  required_files = ['config.json', 'stat_vars.mcf']
  missing = [
      f for f in required_files
      if not file_exists_in_storage(INPUT_DIR, get_blob_location(f))
  ]
  if missing:
    return {
        'category': 'error',
        'message': f'Required files missing: {", ".join(missing)}',
    }, 400

  try:
    proc = subprocess.Popen(
        ['bash', '/workspace/run_db_embeddings.sh'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    _write_state({
        'status': 'running',
        'error': None,
        'started_at': datetime.utcnow().isoformat() + 'Z',
        'finished_at': None,
    })
    threading.Thread(
        target=_monitor_db_embeddings,
        args=(proc,),
        daemon=True,
    ).start()
  except Exception as e:
    logging.error(f'Error starting db-sync and embeddings build {e!r}')
    return {
        'category': 'error',
        'message': 'Error starting db-sync and embeddings build',
    }, 400

  return {'category': 'success', 'message': 'DB-sync and embeddings build started'}, 202


@bp.route('/db-sync-and-embeddings-build-status', methods=['GET'])
@require_login
def db_sync_and_embeddings_build_status():
  """Return the current status of the background db-sync and embeddings build."""
  state = _read_state()
  response = {'status': state['status']}
  if state['status'] == 'failed' and state['error']:
    response['error'] = state['error']
  if state['started_at']:
    response['started_at'] = state['started_at']
  if state['finished_at']:
    response['finished_at'] = state['finished_at']

  return response, 200
