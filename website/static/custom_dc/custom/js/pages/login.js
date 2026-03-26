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

import { getApiRoot } from '../utils/api.js';

/**
 * Handle login form submission
 */
async function loginAction() {
  const apiRoot = getApiRoot();
  const formData = new FormData();

  formData.append('username', document.getElementById('username').value);
  formData.append('password', document.getElementById('password').value);

  const response = await fetch(`${apiRoot}/admin/api/login`, {
    method: 'POST',
    body: formData,
  });

  const json_data = await response.json();

  if (response.status !== 200) {
    document.getElementById('loginAlerts').style = "";
    document.getElementById('errorMessage').textContent = json_data.message;
  } else {
    window.location.href = "/admin/dashboard";
  }
}

// Form submit handler
document.getElementById('loginForm').addEventListener('submit', e => {
  e.preventDefault();
  loginAction();
});
