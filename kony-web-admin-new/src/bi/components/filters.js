// src/bi/components/filters.js

// Create a filter panel for the dashboard
export function createFilterPanel(containerId, onChange) {
  const container = document.getElementById(containerId);
  
  if (!container) {
    console.error(`Container with ID ${containerId} not found`);
    return;
  }
  
  // Clear previous content
  container.innerHTML = '';
  
  // Create filter panel structure
  container.innerHTML = `
    <div class="card shadow-sm mb-4">
      <div class="card-header bg-light py-3">
        <div class="d-flex justify-content-between align-items-center">
          <h5 class="mb-0">
            <i class="bi bi-funnel me-2"></i>
            Filters
          </h5>
          <button type="button" class="btn btn-sm btn-outline-secondary" id="toggleFilters">
            <i class="bi bi-chevron-down"></i>
          </button>
        </div>
      </div>
      <div class="card-body pt-0" id="filterBody">
        <div class="row gy-3 mt-3">
          <!-- Date Range -->
          <div class="col-md-6">
            <label for="dateRangeSelect" class="form-label">Date Range</label>
            <select class="form-select" id="dateRangeSelect">
              <option value="all">All Time</option>
              <option value="today">Today</option>
              <option value="yesterday">Yesterday</option>
              <option value="thisWeek">This Week</option>
              <option value="lastWeek">Last Week</option>
              <option value="thisMonth">This Month</option>
              <option value="last30">Last 30 Days</option>
              <option value="thisQuarter">This Quarter</option>
              <option value="thisYear">This Year</option>
              <option value="lastYear">Last Year</option>
              <option value="custom">Custom Range</option>
            </select>
          </div>
          
          <!-- Status -->
          <div class="col-md-6">
            <label for="statusSelect" class="form-label">Status</label>
            <select class="form-select" id="statusSelect">
              <option value="all">All Statuses</option>
              <option value="draft">Draft</option>
              <option value="submitted">Submitted</option>
              <option value="reviewed">Reviewed</option>
              <option value="approved">Approved</option>
            </select>
          </div>
          
          <!-- Custom Date Range (initially hidden) -->
          <div class="col-md-12" id="customDateContainer" style="display: none;">
            <div class="row gy-2">
              <div class="col-md-6">
                <label for="startDate" class="form-label">Start Date</label>
                <input type="date" class="form-control" id="startDate">
              </div>
              <div class="col-md-6">
                <label for="endDate" class="form-label">End Date</label>
                <input type="date" class="form-control" id="endDate">
              </div>
            </div>
          </div>
          
          <!-- Time Interval -->
          <div class="col-md-6">
            <label for="timeIntervalSelect" class="form-label">Time Grouping</label>
            <select class="form-select" id="timeIntervalSelect">
              <option value="day">Daily</option>
              <option value="week">Weekly</option>
              <option value="month" selected>Monthly</option>
              <option value="quarter">Quarterly</option>
              <option value="year">Yearly</option>
            </select>
          </div>
          
          <!-- Client Filter (to be dynamically populated) -->
          <div class="col-md-6">
            <label for="clientSelect" class="form-label">Client</label>
            <select class="form-select" id="clientSelect">
              <option value="all">All Clients</option>
              <!-- Populated dynamically -->
            </select>
          </div>
          
          <!-- Technician Filter (to be dynamically populated) -->
          <div class="col-md-6">
            <label for="technicianSelect" class="form-label">Technician</label>
            <select class="form-select" id="technicianSelect">
              <option value="all">All Technicians</option>
              <!-- Populated dynamically -->
            </select>
          </div>
          
          <!-- Filter Buttons -->
          <div class="col-md-6 d-flex align-items-end">
            <div class="btn-group w-100">
              <button type="button" class="btn btn-primary" id="applyFilters">
                <i class="bi bi-funnel-fill me-1"></i> Apply Filters
              </button>
              <button type="button" class="btn btn-outline-secondary" id="resetFilters">
                <i class="bi bi-arrow-counterclockwise me-1"></i> Reset
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Add event listeners
  const dateRangeSelect = document.getElementById('dateRangeSelect');
  const customDateContainer = document.getElementById('customDateContainer');
  const toggleFiltersBtn = document.getElementById('toggleFilters');
  const filterBody = document.getElementById('filterBody');
  const applyFiltersBtn = document.getElementById('applyFilters');
  const resetFiltersBtn = document.getElementById('resetFilters');
  
  // Toggle filter panel
// src/bi/components/filters.js (continued)
  // Toggle filter panel
  toggleFiltersBtn.addEventListener('click', () => {
    if (filterBody.style.display === 'none') {
      filterBody.style.display = 'block';
      toggleFiltersBtn.innerHTML = '<i class="bi bi-chevron-up"></i>';
    } else {
      filterBody.style.display = 'none';
      toggleFiltersBtn.innerHTML = '<i class="bi bi-chevron-down"></i>';
    }
  });
  
  // Show/hide custom date range inputs
  dateRangeSelect.addEventListener('change', () => {
    if (dateRangeSelect.value === 'custom') {
      customDateContainer.style.display = 'block';
    } else {
      customDateContainer.style.display = 'none';
    }
  });
  
  // Reset filters
  resetFiltersBtn.addEventListener('click', () => {
    dateRangeSelect.value = 'all';
    document.getElementById('statusSelect').value = 'all';
    document.getElementById('timeIntervalSelect').value = 'month';
    document.getElementById('clientSelect').value = 'all';
    document.getElementById('technicianSelect').value = 'all';
    document.getElementById('startDate').value = '';
    document.getElementById('endDate').value = '';
    customDateContainer.style.display = 'none';
    
    // Trigger change callback with reset values
    if (onChange) {
      onChange(getFilterValues());
    }
  });
  
  // Apply filters
  applyFiltersBtn.addEventListener('click', () => {
    if (onChange) {
      onChange(getFilterValues());
    }
  });
  
  // Helper function to get current filter values
  function getFilterValues() {
    const dateRange = dateRangeSelect.value;
    let startDate = null;
    let endDate = null;
    
    // Calculate date range based on selection
    if (dateRange === 'custom') {
      startDate = document.getElementById('startDate').value || null;
      endDate = document.getElementById('endDate').value || null;
      
      if (startDate) startDate = new Date(startDate);
      if (endDate) {
        endDate = new Date(endDate);
        endDate.setHours(23, 59, 59, 999); // End of day
      }
    } else {
      const now = new Date();
      
      switch(dateRange) {
        case 'today':
          startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
          break;
        case 'yesterday':
          startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
          endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 23, 59, 59, 999);
          break;
        case 'thisWeek':
          const dayOfWeek = now.getDay();
          const diff = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1); // Adjust when day is Sunday
          startDate = new Date(now.getFullYear(), now.getMonth(), diff);
          endDate = new Date();
          break;
        case 'lastWeek':
          const lastWeekDay = now.getDay();
          const lastWeekDiff = now.getDate() - lastWeekDay - 6;
          startDate = new Date(now.getFullYear(), now.getMonth(), lastWeekDiff);
          endDate = new Date(now.getFullYear(), now.getMonth(), lastWeekDiff + 6, 23, 59, 59, 999);
          break;
        case 'thisMonth':
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          endDate = new Date();
          break;
        case 'last30':
          startDate = new Date();
          startDate.setDate(now.getDate() - 30);
          endDate = new Date();
          break;
        case 'thisQuarter':
          const quarter = Math.floor(now.getMonth() / 3);
          startDate = new Date(now.getFullYear(), quarter * 3, 1);
          endDate = new Date();
          break;
        case 'thisYear':
          startDate = new Date(now.getFullYear(), 0, 1);
          endDate = new Date();
          break;
        case 'lastYear':
          startDate = new Date(now.getFullYear() - 1, 0, 1);
          endDate = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59, 999);
          break;
      }
    }
    
    // Get other filter values
    const status = document.getElementById('statusSelect').value;
    const timeInterval = document.getElementById('timeIntervalSelect').value;
    const client = document.getElementById('clientSelect').value;
    const technician = document.getElementById('technicianSelect').value;
    
    return {
      dateRange,
      startDate,
      endDate,
      status: status === 'all' ? null : status,
      timeInterval,
      client: client === 'all' ? null : client,
      technician: technician === 'all' ? null : technician
    };
  }
  
  return {
    updateOptions: function(clients = [], technicians = []) {
      // Populate client dropdown
      const clientSelect = document.getElementById('clientSelect');
      
      // Keep the first "All Clients" option
      while (clientSelect.childNodes.length > 1) {
        clientSelect.removeChild(clientSelect.lastChild);
      }
      
      // Add client options
      clients.forEach(client => {
        if (!client) return; // Skip empty client names
        
        const option = document.createElement('option');
        option.value = client;
        option.textContent = client;
        clientSelect.appendChild(option);
      });
      
      // Populate technician dropdown
      const technicianSelect = document.getElementById('technicianSelect');
      
      // Keep the first "All Technicians" option
      while (technicianSelect.childNodes.length > 1) {
        technicianSelect.removeChild(technicianSelect.lastChild);
      }
      
      // Add technician options
      technicians.forEach(tech => {
        if (!tech) return; // Skip empty technician names
        
        const option = document.createElement('option');
        option.value = tech;
        option.textContent = tech;
        technicianSelect.appendChild(option);
      });
    },
    
    getFilters: getFilterValues
  };
}