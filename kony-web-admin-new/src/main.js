import './style.css';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './firebase/config.js';
import { getUserRole } from './utils/auth.js';
import { showLoginForm } from './components/login.js';
import { showDashboard } from './components/dashboard.js';

console.log('Initializing Kony Web Admin Dashboard');

// Main application initialization
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, setting up auth listener');
  
  // Listen for auth state changes
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      console.log('User is signed in:', user.email);
      
      // Check if user is admin
      const role = await getUserRole(user.uid);
      console.log('User role:', role);
      
      if (role === 'admin') {
        showDashboard();
      } else {
        // Not an admin, sign out
        auth.signOut();
        showLoginForm('Only administrators can access this dashboard.');
      }
    } else {
      console.log('User is signed out');
      showLoginForm();
    }
  });
});