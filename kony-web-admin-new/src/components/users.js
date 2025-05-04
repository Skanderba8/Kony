import { getUsers, updateUser, deleteUser } from '../utils/api.js';

/**
 * Shows the users list
 */
export async function showUsersList() {
  console.log('Showing users list');
  const contentContainer = document.getElementById('contentContainer');
  
  // Show loading state
  contentContainer.innerHTML = `
    <div class="text-center py-5">
      <div class="spinner-border text-primary" role="status"></div>
      <p class="mt-2">Loading users...</p>
    </div>
  `;
  
  // Create users UI
  contentContainer.innerHTML = `
    <div class="row mb-4">
      <div class="col-12">
        <div class="card">
          <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h5 class="mb-0">User Management</h5>
            <button class="btn btn-primary" id="addUserBtn" disabled>
              <i class="bi bi-person-plus"></i> Add User
            </button>
          </div>
          <div class="card-body">
            <div id="usersContainer">
              <!-- Users will be loaded here -->
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Add event listener for add user button
  document.getElementById('addUserBtn').addEventListener('click', () => {
    alert('Adding new users through the web interface is not implemented yet. Please use the Firebase console to add new users.');
  });
  
  // Load users
  await loadUsers();
}

/**
 * Load users
 */
async function loadUsers() {
  const usersContainer = document.getElementById('usersContainer');
  
  try {
    // Show loading state
    usersContainer.innerHTML = `
      <div class="text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-2">Loading users...</p>
      </div>
    `;
    
    // Fetch users
    const users = await getUsers();
    
    if (users.length === 0) {
      usersContainer.innerHTML = `
        <div class="text-center py-5">
          <div class="display-6 text-muted">No users found</div>
          <p class="text-muted">Users will appear here when added</p>
        </div>
      `;
      return;
    }
    
    // Render users table
    usersContainer.innerHTML = `
      <div class="table-responsive">
        <table class="table table-hover">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>ID</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            ${users.map(user => `
              <tr data-id="${user.id}" data-auth-uid="${user.authUid || ''}">
                <td>${user.name}</td>
                <td>${user.email}</td>
                <td>
                  <span class="badge ${user.role === 'admin' ? 'bg-danger' : 'bg-primary'}">${user.role}</span>
                </td>
                <td><small class="text-muted">${user.id}</small></td>
                <td>
                  <button class="btn btn-sm btn-outline-primary edit-user-btn" data-id="${user.id}">
                    <i class="bi bi-pencil"></i> Edit
                  </button>
                  <button class="btn btn-sm btn-outline-danger delete-user-btn" data-id="${user.id}">
                    <i class="bi bi-trash"></i> Delete
                  </button>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
    
    // Add event listeners for user actions
    users.forEach(user => {
      // Edit button
      document.querySelector(`.edit-user-btn[data-id="${user.id}"]`)?.addEventListener('click', () => {
        showEditUserModal(user);
      });
      
      // Delete button
      document.querySelector(`.delete-user-btn[data-id="${user.id}"]`)?.addEventListener('click', () => {
        confirmDeleteUser(user);
      });
    });
  } catch (error) {
    console.error('Error loading users:', error);
    usersContainer.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle"></i> Error loading users: ${error.message}
      </div>
    `;
  }
}

/**
 * Show edit user modal
 */
function showEditUserModal(user) {
  const userModal = new bootstrap.Modal(document.getElementById('userModal'));
  const userForm = document.getElementById('userForm');
  const userModalTitle = document.getElementById('userModalTitle');
  const passwordGroup = document.getElementById('passwordGroup');
  
  // Set form values
  document.getElementById('userId').value = user.id;
  document.getElementById('userAuthUid').value = user.authUid || '';
  document.getElementById('userName').value = user.name;
  document.getElementById('userEmail').value = user.email;
  document.getElementById('userRole').value = user.role;
  
  // Hide password field for editing
  passwordGroup.style.display = 'none';
  
  // Set modal title
  userModalTitle.textContent = 'Edit User';
  
  // Add save button event listener
  const saveUserBtn = document.getElementById('saveUserBtn');
  const saveHandler = async () => {
    if (!userForm.checkValidity()) {
      userForm.reportValidity();
      return;
    }
    
    try {
      const authUid = document.getElementById('userAuthUid').value;
      if (!authUid) {
        alert('User has no auth UID. Cannot update.');
        return;
      }
      
      await updateUser(authUid, {
        name: document.getElementById('userName').value,
        email: document.getElementById('userEmail').value,
        role: document.getElementById('userRole').value
      });
      
      userModal.hide();
      await loadUsers();
    } catch (error) {
      console.error('Error updating user:', error);
      alert(`Error updating user: ${error.message}`);
    }
  };
  
  // Remove any existing event listeners
  saveUserBtn.replaceWith(saveUserBtn.cloneNode(true));
  
  // Add new event listener
  document.getElementById('saveUserBtn').addEventListener('click', saveHandler);
  
  userModal.show();
}

/**
 * Confirm and delete user
 */
async function confirmDeleteUser(user) {
  if (!confirm(`Are you sure you want to delete user "${user.name}"? This action cannot be undone.`)) {
    return;
  }
  
  try {
    const authUid = user.authUid || user.id;
    await deleteUser(authUid);
    await loadUsers();
  } catch (error) {
    console.error('Error deleting user:', error);
    alert(`Error deleting user: ${error.message}`);
  }
}