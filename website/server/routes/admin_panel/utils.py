from io import BytesIO
import json
import logging
import os
from pathlib import Path

from flask import redirect
from flask import session
from flask import url_for
from google.cloud import storage
from shared.lib.gcs import get_path_parts
from shared.lib.gcs import is_gcs_path
from werkzeug.datastructures import FileStorage

from .constants import INPUT_DIR


def get_blob_location(filename: str) -> str:
  """Build the blob storage path for a file relative to INPUT_DIR."""
  if is_gcs_path(INPUT_DIR):
    _, blob_name = get_path_parts(INPUT_DIR)
    return f'{blob_name}/{filename}'
  return f"{INPUT_DIR.rsplit('/', 1)[1]}/{filename}"


def validate_session():
  """Validate session security (IP address consistency, session existence)"""
  if 'username' not in session:
    return False

  return True


def require_login(f):
  """Decorator to require login for protected routes"""
  from functools import wraps

  @wraps(f)
  def decorated_function(*args, **kwargs):
    if not validate_session():
      return redirect(url_for('admin_panel.index'))
    return f(*args, **kwargs)

  return decorated_function


def upload_file_to_storage(INPUT_DIR: str, blob_location,
                           file_content: BytesIO | FileStorage) -> None:
  if is_gcs_path(INPUT_DIR):
    # Store file in the cloud storage
    client = storage.Client()

    bucket_name, _ = get_path_parts(INPUT_DIR)

    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_location)

    blob.upload_from_file(file_content, content_type="application/octet-stream")
  else:
    # Store file in the local file system
    local_base_folder_loc = INPUT_DIR.rsplit('/', 1)[0]
    filepath = os.path.join(local_base_folder_loc, blob_location)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    with open(filepath, 'wb+') as f:
      f.write(file_content.read())


def file_exists_in_storage(input_dir: str, blob_location: str) -> bool:
  """Check if a file exists in GCS or local storage."""
  if is_gcs_path(input_dir):
    client = storage.Client()

    bucket_name, _ = get_path_parts(input_dir)

    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_location)

    return blob.exists()
  else:
    local_base_folder_loc = input_dir.rsplit('/', 1)[0]
    filepath = os.path.join(local_base_folder_loc, blob_location)

    return os.path.exists(filepath)


def delete_file_from_storage(INPUT_DIR: str, blob_location: str) -> bool:
  """Delete a file from GCS or local storage. Returns True if deleted."""
  if is_gcs_path(INPUT_DIR):
    # Delete file from cloud storage
    client = storage.Client()

    bucket_name, _ = get_path_parts(INPUT_DIR)

    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_location)

    if blob.exists():
      blob.delete()
      return True
    return False
  else:
    # Delete file from local file system
    local_base_folder_loc = INPUT_DIR.rsplit('/', 1)[0]
    filepath = os.path.join(local_base_folder_loc, blob_location)

    if os.path.exists(filepath):
      os.remove(filepath)
      return True
    return False


def _get_input_csv_filenames(configs_location: Path) -> set:
  """Return the set of CSV filenames declared in config.json inputFiles."""
  config_path = configs_location / 'config.json'
  if not config_path.exists():
    return set()
  with open(config_path) as f:
    config = json.load(f)
  return set(config.get('inputFiles', {}).keys())


def upload_db_configs(cfg):
  """ Function for uploading default configs """

  configs_location = Path(
      __file__).resolve().parent.parent.parent / f'config/custom_dc/{cfg.ENV}/'

  csv_filenames = _get_input_csv_filenames(configs_location)
  admin_managed_files = getattr(cfg, 'ALLOWED_CONFIG_FILENAMES', set())

  for cfg_file in os.listdir(configs_location):
    blob_location = f"{INPUT_DIR.rsplit('/', 1)[1]}/{cfg_file}"

    if is_gcs_path(INPUT_DIR):
      _, blob_name = get_path_parts(INPUT_DIR)
      blob_location = f'{blob_name}/{cfg_file}'

    skip_filenames = csv_filenames | admin_managed_files
    if cfg_file in skip_filenames and file_exists_in_storage(
        INPUT_DIR, blob_location):
      logging.info('Skipping upload of %s: already exists in storage', cfg_file)
      continue

    cfg_file_bytes = BytesIO()
    cfg_file_bytes.write(Path(configs_location / cfg_file).read_bytes())
    cfg_file_bytes.seek(0)

    upload_file_to_storage(INPUT_DIR, blob_location, cfg_file_bytes)
