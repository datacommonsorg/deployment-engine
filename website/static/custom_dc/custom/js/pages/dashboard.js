/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Note: This file uses legacy imports via window globals from alert.js

function getApiRoot() {
  const params = new URLSearchParams(location.search);
  return params.get("apiRoot") || location.origin || "https://datacommons.org";
}


// Reusable File Upload Functions
const selectedFiles = {
  applicant: null
};

const DEFAULT_MAX_UPLOAD_FILE_SIZE_MB = 10;

function getMaxUploadFileSizeMb() {
  const fileInput = document.getElementById('applicantFileInput');
  const configuredLimit = Number(fileInput?.dataset.maxFileSizeMb);
  if (Number.isFinite(configuredLimit) && configuredLimit > 0) {
    return configuredLimit;
  }
  return DEFAULT_MAX_UPLOAD_FILE_SIZE_MB;
}

function getMaxUploadFileSizeBytes() {
  return getMaxUploadFileSizeMb() * 1024 * 1024;
}

function getMaxUploadFileSizeLabel() {
  return formatFileSize(getMaxUploadFileSizeBytes());
}

function handleFileSelect(event, fileType) {
  const file = event.target.files[0];
  if (!file) return;

  if (!file.name.endsWith('.csv')) {
    alert('Please upload a CSV file');
    event.target.value = '';
    return;
  }

  if (file.size > getMaxUploadFileSizeBytes()) {
    alert(`File is too large. Maximum file size is ${getMaxUploadFileSizeLabel()}.`);
    event.target.value = '';
    return;
  }

  selectedFiles[fileType] = file;

  const display = document.getElementById('selectedFileDisplay');
  const fileName = document.getElementById('selectedFileName');
  const fileSize = document.getElementById('selectedFileSize');

  fileName.textContent = file.name;
  fileSize.textContent = formatFileSize(file.size);
  display.classList.add('show');

  document.getElementById('uploadDataBtn').removeAttribute('disabled');
}

function removeFile(fileType) {
  selectedFiles[fileType] = null;
  document.getElementById('applicantFileInput').value = '';
  document.getElementById('selectedFileDisplay').classList.remove('show');
  document.getElementById('uploadDataBtn').setAttribute('disabled', '');
}

function isNumber(v) {
  return typeof v === "number" && Number.isFinite(v); // excludes NaN, Infinity
}

async function uploadDataFile() {
  const apiRoot = getApiRoot();

  const formData = new FormData();

  formData.append('file', selectedFiles.applicant);

  const response = await fetch(`${apiRoot}/admin/api/upload`, {
    method: 'POST',
    body: formData,
  });

  let json_data = {};
  try {
    json_data = await response.json();
  } catch (parseError) {
    // 413 responses may be plain text/html from the proxy.
    json_data = {};
  }

  // Show the response message container
  document.getElementById('uploadResponseMessage').classList.remove('hidden');

  if (response.status !== 200) {
    document.getElementById('successUploadStatus').classList.add('hidden');
    document.getElementById('failedUploadStatus').classList.remove('hidden');
    document.getElementById('uploadStatusMessage').textContent = `Upload failed for "${selectedFiles.applicant?.name ?? 'file'}"`;

    document.getElementById('uploadErrorBlock').classList.remove('hidden');
    const errorMessage = response.status === 413
      ? `File is too large. Maximum file size is ${getMaxUploadFileSizeLabel()}.`
      : (json_data.message || 'An error occurred during upload.');
    if (response.status === 413) {
      alert(errorMessage);
    }
    let errorHtml = `<h4 class="error-title">Errors:</h4><p class="error-item">${errorMessage}</p>`;

    // Display validation errors (failed lines) if present
    if (json_data.validation_errors && json_data.validation_errors.length > 0) {
      errorHtml += `<h5 class="error-subtitle">Unacceptable cells:</h5><ul class="error-list">`;
      json_data.validation_errors.forEach(error => {
        errorHtml += `<li class="error-item">${error}</li>`;
      });
      errorHtml += `</ul>`;
    }

    document.getElementById('uploadErrorBlock').innerHTML = errorHtml;
  } else {
    document.getElementById('failedUploadStatus').classList.add('hidden');
    document.getElementById('uploadErrorBlock').classList.add('hidden');
    document.getElementById('successUploadStatus').classList.remove('hidden');
    document.getElementById('uploadStatusMessage').textContent = json_data.message;
  }

  if (isNumber(json_data.valid_rows_count)) {
    document.getElementById('rowsUploaded').classList.remove('hidden');
    document.getElementById('rowsUploadedsMessage').textContent = json_data.valid_rows_count;
  } else {
    document.getElementById('rowsUploaded').classList.add('hidden');
  }

  if (isNumber(json_data.invalid_rows_count)) {
    document.getElementById('failedRows').classList.remove('hidden');
    document.getElementById('failedRowsMessage').textContent = json_data.invalid_rows_count;
    document.getElementById('failedRowsMessage').style.color = json_data.invalid_rows_count > 0 ? 'red' : '';
  } else {
    document.getElementById('failedRows').classList.add('hidden');
  }

}

function uploadApplicantFile() {
  if (!selectedFiles.applicant) {
    alert('Please select a file first');
    return;
  }

  uploadDataFile();
}

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function logout() {
  const apiRoot = getApiRoot();

  fetch(`${apiRoot}/admin/api/logout`, {
    method: 'POST',
  }).then((r) => {
    window.location.href = '/';
  })
}

// Config file upload (config.json and stat_vars.mcf)
const selectedConfigFiles = {
  config: null,
  statvars: null
};

function handleConfigFileSelect(event, fileType) {
  const file = event.target.files[0];
  if (!file) return;

  if (fileType === 'config' && !file.name.endsWith('.json')) {
    alert('Please upload a JSON file');
    event.target.value = '';
    return;
  }

  if (fileType === 'statvars' && !file.name.endsWith('.mcf')) {
    alert('Please upload an MCF file');
    event.target.value = '';
    return;
  }

  selectedConfigFiles[fileType] = file;

  const displayId = fileType === 'config' ? 'selectedConfigDisplay' : 'selectedStatvarsDisplay';
  const nameId = fileType === 'config' ? 'selectedConfigName' : 'selectedStatvarsName';
  const btnId = fileType === 'config' ? 'uploadConfigBtn' : 'uploadStatvarsBtn';

  const display = document.getElementById(displayId);
  const fileName = document.getElementById(nameId);

  if (fileName) fileName.textContent = file.name;
  if (display) display.classList.add('show');

  document.getElementById(btnId).removeAttribute('disabled');
}

function removeConfigFile(fileType) {
  selectedConfigFiles[fileType] = null;

  const inputId = fileType === 'config' ? 'configFileInput' : 'statvarsFileInput';
  const displayId = fileType === 'config' ? 'selectedConfigDisplay' : 'selectedStatvarsDisplay';
  const btnId = fileType === 'config' ? 'uploadConfigBtn' : 'uploadStatvarsBtn';

  document.getElementById(inputId).value = '';
  document.getElementById(displayId).classList.remove('show');
  document.getElementById(btnId).setAttribute('disabled', '');
}

async function uploadConfigFile(fileType) {
  const file = selectedConfigFiles[fileType];
  if (!file) {
    alert('Please select a file first');
    return;
  }

  const apiRoot = getApiRoot();
  const formData = new FormData();
  formData.append('file', file);

  const responseMessageId = fileType === 'config' ? 'configUploadResponseMessage' : 'statvarsUploadResponseMessage';
  const successStatusId = fileType === 'config' ? 'successConfigUploadStatus' : 'successStatvarsUploadStatus';
  const failedStatusId = fileType === 'config' ? 'failedConfigUploadStatus' : 'failedStatvarsUploadStatus';
  const statusMessageId = fileType === 'config' ? 'configUploadStatusMessage' : 'statvarsUploadStatusMessage';
  const errorBlockId = fileType === 'config' ? 'configUploadErrorBlock' : 'statvarsUploadErrorBlock';

  const response = await fetch(`${apiRoot}/admin/api/upload-config`, {
    method: 'POST',
    body: formData,
  });

  let json_data = {};
  try {
    json_data = await response.json();
  } catch (parseError) {
    json_data = {};
  }

  document.getElementById(responseMessageId).classList.remove('hidden');

  if (response.status === 200) {
    document.getElementById(failedStatusId).classList.add('hidden');
    document.getElementById(errorBlockId).classList.add('hidden');
    document.getElementById(successStatusId).classList.remove('hidden');
    document.getElementById(statusMessageId).textContent = json_data.message;
    showMsgAlert('success', json_data.message);
  } else {
    document.getElementById(successStatusId).classList.add('hidden');
    document.getElementById(failedStatusId).classList.remove('hidden');
    const errorMessage = json_data.message || 'An error occurred during upload.';
    document.getElementById(statusMessageId).textContent = errorMessage;
    document.getElementById(errorBlockId).classList.remove('hidden');
    document.getElementById(errorBlockId).innerHTML =
      `<h4 class="error-title">Errors:</h4><p class="error-item">${errorMessage}</p>`;
    showMsgAlert('error', errorMessage);
  }
}

// DB Sync & Embeddings Build
let dbSyncPollingTimer = null;

function formatUtcToLocal(utcIsoString) {
  const date = new Date(utcIsoString);
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  const yyyy = date.getFullYear();
  const hh = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  return `${mm}/${dd}/${yyyy} ${hh}:${min}`;
}

function showDbSyncRunningState(data) {
  document.getElementById('dbSyncBtn').disabled = true;
  document.getElementById('dbSyncStatus').classList.remove('hidden');
  document.getElementById('dbSyncRunningChip').classList.remove('hidden');
  document.getElementById('dbSyncSuccessChip').classList.add('hidden');
  document.getElementById('dbSyncFailedChip').classList.add('hidden');
  document.getElementById('dbSyncErrorRow').classList.add('hidden');
  document.getElementById('dbSyncFinishedAtRow').classList.add('hidden');

  if (data && data.started_at) {
    document.getElementById('dbSyncStartedAt').textContent = formatUtcToLocal(data.started_at);
    document.getElementById('dbSyncStartedAtRow').classList.remove('hidden');
  } else {
    document.getElementById('dbSyncStartedAtRow').classList.add('hidden');
  }
}

function showDbSyncResult(data) {
  document.getElementById('dbSyncStatus').classList.remove('hidden');
  document.getElementById('dbSyncRunningChip').classList.add('hidden');
  document.getElementById('dbSyncSuccessChip').classList.add('hidden');
  document.getElementById('dbSyncFailedChip').classList.add('hidden');
  document.getElementById('dbSyncErrorRow').classList.add('hidden');
  document.getElementById('dbSyncStartedAtRow').classList.add('hidden');
  document.getElementById('dbSyncFinishedAtRow').classList.add('hidden');
  document.getElementById('dbSyncBtn').disabled = false;

  if (data.status === 'completed') {
    document.getElementById('dbSyncSuccessChip').classList.remove('hidden');
  } else if (data.status === 'failed') {
    document.getElementById('dbSyncFailedChip').classList.remove('hidden');
    document.getElementById('dbSyncErrorRow').classList.remove('hidden');
    document.getElementById('dbSyncErrorMessage').textContent = data.error || 'Unknown error';
  }

  if (data.started_at) {
    document.getElementById('dbSyncStartedAt').textContent = formatUtcToLocal(data.started_at);
    document.getElementById('dbSyncStartedAtRow').classList.remove('hidden');
  }
  if (data.finished_at) {
    document.getElementById('dbSyncFinishedAt').textContent = formatUtcToLocal(data.finished_at);
    document.getElementById('dbSyncFinishedAtRow').classList.remove('hidden');
  }
}

async function startDbSyncAndEmbeddingsBuild() {
  const apiRoot = getApiRoot();
  showDbSyncRunningState();

  try {
    const res = await fetch(`${apiRoot}/admin/api/run-db-sync-and-embeddings-build`, { method: 'POST' });
    const data = await res.json();
    if (res.status === 409) {
      showMsgAlert('error', 'Data sync and embeddings build is already in progress');
      pollDbSyncStatus();
      return;
    }
    if (!res.ok) {
      showMsgAlert('error', data.message || 'Failed to start');
      showDbSyncResult({ status: 'failed', error: data.message || 'Failed to start' });
      return;
    }
    pollDbSyncStatus();
  } catch (e) {
    showMsgAlert('error', 'Failed to start data sync and embeddings build');
    document.getElementById('dbSyncBtn').disabled = false;
    document.getElementById('dbSyncStatus').classList.add('hidden');
  }
}

function pollDbSyncStatus() {
  const apiRoot = getApiRoot();
  dbSyncPollingTimer = setTimeout(async () => {
    try {
      const res = await fetch(`${apiRoot}/admin/api/db-sync-and-embeddings-build-status`);
      const data = await res.json();

      if (data.status === 'running') {
        showDbSyncRunningState(data);
        pollDbSyncStatus();
        return;
      }

      showDbSyncResult(data);
      if (data.status === 'completed') {
        showMsgAlert('success', 'Data sync and embeddings build completed');
      } else if (data.status === 'failed') {
        showMsgAlert('error', 'Data sync and embeddings build failed');
      }
    } catch (e) {
      document.getElementById('dbSyncRunningChip').classList.add('hidden');
      document.getElementById('dbSyncBtn').disabled = false;
      showMsgAlert('error', 'Error checking build status');
    }
  }, 1000);
}

async function checkDbSyncStatusOnLoad() {
  const apiRoot = getApiRoot();
  try {
    const res = await fetch(`${apiRoot}/admin/api/db-sync-and-embeddings-build-status`);
    const data = await res.json();
    if (data.status === 'running') {
      showDbSyncRunningState(data);
      pollDbSyncStatus();
    }
  } catch (e) {
    // Silently ignore -- button stays enabled in idle state
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', checkDbSyncStatusOnLoad);
} else {
  checkDbSyncStatusOnLoad();
}

