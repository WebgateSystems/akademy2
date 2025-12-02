// API Client for communicating with Rails API
class ApiClient {
  constructor() {
    this.baseURL = '/api/v1';
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  }

  getAuthToken() {
    // Try to get token from meta tag (set by Rails)
    // Check for admin-token first (for admin dashboard)
    const adminTokenMeta = document.querySelector('meta[name="admin-token"]');
    if (adminTokenMeta) {
      return adminTokenMeta.getAttribute('content');
    }
    // Check for management-token (for management dashboard)
    const managementTokenMeta = document.querySelector('meta[name="management-token"]');
    if (managementTokenMeta) {
      return managementTokenMeta.getAttribute('content');
    }
    // Check for dashboard-token (for teacher dashboard)
    const dashboardTokenMeta = document.querySelector('meta[name="dashboard-token"]');
    if (dashboardTokenMeta) {
      return dashboardTokenMeta.getAttribute('content');
    }
    return null;
  }

  getHeaders(contentType = 'application/json') {
    const headers = {
      'Content-Type': contentType,
    };

    if (this.csrfToken) {
      headers['X-CSRF-Token'] = this.csrfToken;
    }

    const authToken = this.getAuthToken();
    if (authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
    }

    return headers;
  }

  async request(method, path, data = null) {
    const url = `${this.baseURL}${path}`;
    const options = {
      method,
      headers: this.getHeaders(),
    };

    if (data) {
      if (data instanceof FormData) {
        // Remove Content-Type for FormData to let browser set it with boundary
        delete options.headers['Content-Type'];
        options.body = data;
      } else {
        options.body = JSON.stringify(data);
      }
    }

    try {
      const response = await fetch(url, options);
      const contentType = response.headers.get('content-type');
      
      let responseData;
      if (contentType && contentType.includes('application/json')) {
        responseData = await response.json();
      } else {
        responseData = await response.text();
      }

      if (!response.ok) {
        console.error('API request failed:', {
          status: response.status,
          statusText: response.statusText,
          url: url,
          responseData: responseData
        });
        
        // Extract error message from response
        let errorMessage;
        if (Array.isArray(responseData.errors)) {
          errorMessage = responseData.errors;
        } else if (responseData.errors) {
          errorMessage = responseData.errors;
        } else if (responseData.error) {
          errorMessage = responseData.error;
        } else {
          errorMessage = `HTTP ${response.status}: ${response.statusText}`;
        }
        
        return { success: false, error: errorMessage, errors: Array.isArray(errorMessage) ? errorMessage : [errorMessage] };
      }

      return { success: true, data: responseData };
    } catch (error) {
      console.error('API request failed:', error);
      return { success: false, error: error.message, errors: [error.message] };
    }
  }

  async get(path) {
    return this.request('GET', path);
  }

  async post(path, data) {
    return this.request('POST', path, data);
  }

  async patch(path, data) {
    return this.request('PATCH', path, data);
  }

  async delete(path) {
    return this.request('DELETE', path);
  }
}

// Export for use in other modules (both ES6 and global)
// Make sure it's available immediately for inline scripts
if (typeof window !== 'undefined') {
  window.ApiClient = ApiClient;
}
export default ApiClient;

