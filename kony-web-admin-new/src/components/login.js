import { signIn } from '../utils/auth.js';

/**
 * Displays the login form
 */
export function showLoginForm(errorMessage = null) {
  console.log('Showing login form');
  const appContainer = document.getElementById('app');
  
  appContainer.innerHTML = `
    <div class="login-container">
      <div class="login-logo">
        <h1>Kony Admin</h1>
      </div>
      <div class="card login-card">
        <div class="login-header">
          <h4 class="mb-0">Admin Login</h4>
        </div>
        <div class="card-body p-4">
          <form id="loginForm">
            <div class="mb-3">
              <label for="email" class="form-label">Email</label>
              <input type="email" class="form-control" id="email" required>
            </div>
            <div class="mb-3">
              <label for="password" class="form-label">Password</label>
              <input type="password" class="form-control" id="password" required>
            </div>
            ${errorMessage ? `<div class="alert alert-danger">${errorMessage}</div>` : ''}
            <div class="d-grid">
              <button type="submit" class="btn btn-primary" id="loginButton">Login</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  `;
  
  // Add form submission handler
  document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const loginButton = document.getElementById('loginButton');
    
    try {
      // Disable button and show loading
      loginButton.disabled = true;
      loginButton.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Logging in...';
      
      await signIn(email, password);
      // Auth state observer will handle the navigation
    } catch (error) {
      loginButton.disabled = false;
      loginButton.innerHTML = 'Login';
      
      showLoginForm(error.message || 'Login failed. Please check your credentials.');
    }
  });
}