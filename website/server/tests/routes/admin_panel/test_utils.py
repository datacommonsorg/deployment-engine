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

import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock
from unittest.mock import patch

from server.routes.admin_panel.utils import _get_input_csv_filenames
from server.routes.admin_panel.utils import file_exists_in_storage
from server.routes.admin_panel.utils import upload_db_configs


class TestFileExistsInStorage(unittest.TestCase):
  """Test file_exists_in_storage function."""

  @patch('server.routes.admin_panel.utils.storage.Client')
  @patch('server.routes.admin_panel.utils.get_path_parts',
         return_value=('my-bucket', 'data'))
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=True)
  def test_gcs_blob_exists(self, mock_is_gcs, mock_parts, mock_client_cls):
    """Returns True when GCS blob exists."""
    mock_blob = MagicMock()
    mock_blob.exists.return_value = True
    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob
    mock_client_cls.return_value.bucket.return_value = mock_bucket

    result = file_exists_in_storage('gs://my-bucket/data', 'data/leases.csv')

    assert result is True
    mock_bucket.blob.assert_called_once_with('data/leases.csv')

  @patch('server.routes.admin_panel.utils.storage.Client')
  @patch('server.routes.admin_panel.utils.get_path_parts',
         return_value=('my-bucket', 'data'))
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=True)
  def test_gcs_blob_not_exists(self, mock_is_gcs, mock_parts,
                               mock_client_cls):
    """Returns False when GCS blob does not exist."""
    mock_blob = MagicMock()
    mock_blob.exists.return_value = False
    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob
    mock_client_cls.return_value.bucket.return_value = mock_bucket

    result = file_exists_in_storage('gs://my-bucket/data', 'data/leases.csv')

    assert result is False

  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=False)
  def test_local_file_exists(self, mock_is_gcs):
    """Returns True when local file exists."""
    with tempfile.TemporaryDirectory() as tmpdir:
      os.makedirs(os.path.join(tmpdir, 'input'), exist_ok=True)
      filepath = os.path.join(tmpdir, 'input', 'leases.csv')
      Path(filepath).touch()

      input_dir = f'{tmpdir}/input'
      result = file_exists_in_storage(input_dir, 'input/leases.csv')

      assert result is True

  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=False)
  def test_local_file_not_exists(self, mock_is_gcs):
    """Returns False when local file does not exist."""
    with tempfile.TemporaryDirectory() as tmpdir:
      input_dir = f'{tmpdir}/input'
      result = file_exists_in_storage(input_dir, 'input/leases.csv')

      assert result is False


class TestGetInputCsvFilenames(unittest.TestCase):
  """Test _get_input_csv_filenames function."""

  def test_returns_csv_filenames_from_config(self):
    """Extracts inputFiles keys from config.json."""
    with tempfile.TemporaryDirectory() as tmpdir:
      config = {
          'inputFiles': {
              'leases.csv': {
                  'provenance': 'Energy Insights'
              },
              'asset_locations.csv': {
                  'provenance': 'Energy Insights'
              },
          }
      }
      config_path = Path(tmpdir) / 'config.json'
      config_path.write_text(json.dumps(config))

      result = _get_input_csv_filenames(Path(tmpdir))

      assert result == {'leases.csv', 'asset_locations.csv'}

  def test_returns_empty_set_when_no_config(self):
    """Returns empty set when config.json doesn't exist."""
    with tempfile.TemporaryDirectory() as tmpdir:
      result = _get_input_csv_filenames(Path(tmpdir))

      assert result == set()

  def test_returns_empty_set_when_no_input_files_key(self):
    """Returns empty set when config.json has no inputFiles key."""
    with tempfile.TemporaryDirectory() as tmpdir:
      config = {'variables': {}, 'sources': {}}
      config_path = Path(tmpdir) / 'config.json'
      config_path.write_text(json.dumps(config))

      result = _get_input_csv_filenames(Path(tmpdir))

      assert result == set()

  def test_returns_empty_set_when_input_files_empty(self):
    """Returns empty set when inputFiles is empty."""
    with tempfile.TemporaryDirectory() as tmpdir:
      config = {'inputFiles': {}}
      config_path = Path(tmpdir) / 'config.json'
      config_path.write_text(json.dumps(config))

      result = _get_input_csv_filenames(Path(tmpdir))

      assert result == set()


class TestUploadDbConfigs(unittest.TestCase):
  """Test upload_db_configs skips existing CSV files."""

  def setUp(self):
    import server.routes.admin_panel.utils as utils_module
    self._utils_module = utils_module
    self._original_file = utils_module.__file__

    self._tmpdir = tempfile.mkdtemp()
    env_dir = Path(self._tmpdir) / 'config' / 'custom_dc' / 'test'
    env_dir.mkdir(parents=True)

    config = {
        'inputFiles': {
            'leases.csv': {
                'provenance': 'Test'
            },
        }
    }
    (env_dir / 'config.json').write_text(json.dumps(config))
    (env_dir / 'leases.csv').write_text('dcid,value\ngeoId/01,100')

    fake_file = os.path.join(self._tmpdir, 'server', 'routes',
                             'admin_panel', 'utils.py')
    os.makedirs(os.path.dirname(fake_file), exist_ok=True)
    Path(fake_file).touch()
    self._utils_module.__file__ = fake_file

    self._mock_cfg = MagicMock()
    self._mock_cfg.ENV = 'test'

  def tearDown(self):
    self._utils_module.__file__ = self._original_file

  @patch('server.routes.admin_panel.utils.upload_file_to_storage')
  @patch('server.routes.admin_panel.utils.file_exists_in_storage',
         return_value=True)
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=False)
  @patch('server.routes.admin_panel.utils.INPUT_DIR', '/tmp/base/input')
  def test_skips_csv_that_already_exists(self, mock_is_gcs, mock_exists,
                                         mock_upload):
    """CSV listed in inputFiles is skipped when already in storage."""
    upload_db_configs(self._mock_cfg)

    uploaded = [c.args[1].split('/')[-1] for c in mock_upload.call_args_list]
    assert 'config.json' in uploaded
    assert 'leases.csv' not in uploaded

  @patch('server.routes.admin_panel.utils.upload_file_to_storage')
  @patch('server.routes.admin_panel.utils.file_exists_in_storage',
         return_value=False)
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=False)
  @patch('server.routes.admin_panel.utils.INPUT_DIR', '/tmp/base/input')
  def test_uploads_csv_when_not_in_storage(self, mock_is_gcs, mock_exists,
                                           mock_upload):
    """CSV listed in inputFiles is uploaded when not yet in storage."""
    upload_db_configs(self._mock_cfg)

    uploaded = [c.args[1].split('/')[-1] for c in mock_upload.call_args_list]
    assert 'config.json' in uploaded
    assert 'leases.csv' in uploaded

  @patch('server.routes.admin_panel.utils.upload_file_to_storage')
  @patch('server.routes.admin_panel.utils.file_exists_in_storage',
         return_value=True)
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=False)
  @patch('server.routes.admin_panel.utils.INPUT_DIR', '/tmp/base/input')
  def test_always_uploads_non_csv_files(self, mock_is_gcs, mock_exists,
                                        mock_upload):
    """config.json is always uploaded even when file_exists_in_storage is True."""
    upload_db_configs(self._mock_cfg)

    uploaded = [c.args[1].split('/')[-1] for c in mock_upload.call_args_list]
    assert 'config.json' in uploaded
    assert 'leases.csv' not in uploaded

  @patch('server.routes.admin_panel.utils.upload_file_to_storage')
  @patch('server.routes.admin_panel.utils.file_exists_in_storage',
         return_value=False)
  @patch('server.routes.admin_panel.utils.get_path_parts',
         return_value=('my-bucket', 'data'))
  @patch('server.routes.admin_panel.utils.is_gcs_path', return_value=True)
  @patch('server.routes.admin_panel.utils.INPUT_DIR', 'gs://my-bucket/data')
  def test_gcs_blob_location(self, mock_is_gcs, mock_parts, mock_exists,
                             mock_upload):
    """Blob location is computed correctly for GCS paths."""
    upload_db_configs(self._mock_cfg)

    blob_locations = [c.args[1] for c in mock_upload.call_args_list]
    assert all(loc.startswith('data/') for loc in blob_locations)


if __name__ == '__main__':
  unittest.main()
