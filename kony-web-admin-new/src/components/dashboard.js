import { showReportsList } from './reports.js';
import { showUsersList } from './users.js';
import { logOut } from '../utils/auth.js';
import { initializeBIDashboard } from '../dashboard.js';

/**
 * Shows the dashboard layout
 */
export function showDashboard() {
  console.log('Showing dashboard');
  const appContainer = document.getElementById('app');
  
  // Create dashboard layout
  appContainer.innerHTML = `
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="#">Kony Admin</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
          <ul class="navbar-nav me-auto">
            <li class="nav-item">
              <a class="nav-link active" href="#" id="reportsLink">Reports</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#" id="usersLink">Users</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#" id="biDashboardLink">BI Dashboard</a>
            </li>
          </ul>
          <button class="btn btn-outline-light" id="logoutButton">Logout</button>
        </div>
      </div>
    </nav>
    
    <div class="container-fluid mt-4">
      <div id="contentContainer">
        <!-- Content will be loaded here -->
      </div>
    </div>
  `;
  
  // Add event listeners
  document.getElementById('reportsLink').addEventListener('click', (e) => {
    e.preventDefault();
    setActiveNavLink('reportsLink');
    showReportsList();
  });
  
  document.getElementById('usersLink').addEventListener('click', (e) => {
    e.preventDefault();
    setActiveNavLink('usersLink');
    showUsersList();
  });
  
  document.getElementById('biDashboardLink').addEventListener('click', (e) => {
    e.preventDefault();
    setActiveNavLink('biDashboardLink');
    initializeBIDashboard(document.getElementById('contentContainer'));
  });
  
  document.getElementById('logoutButton').addEventListener('click', async () => {
    try {
      await logOut();
      // Auth state observer will handle redirection
    } catch (error) {
      console.error('Logout error:', error);
      alert('Error logging out: ' + error.message);
    }
  });
  
  // Show reports section by default
  showReportsList();
}

/**
 * Set active navigation link
 */
function setActiveNavLink(activeId) {
  const navLinks = document.querySelectorAll('.navbar-nav .nav-link');
  navLinks.forEach(link => link.classList.remove('active'));
  document.getElementById(activeId).classList.add('active');
}