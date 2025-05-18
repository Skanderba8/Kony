// src/dashboard.js

/**
 * Initializes the Business Intelligence dashboard
 * @param {HTMLElement} container - The container element to render the dashboard
 */
export function initializeBIDashboard(container) {
  console.log('Initializing BI Dashboard');
  
  // Create dashboard UI
  container.innerHTML = `
    <div class="row mb-4">
      <div class="col-12">
        <div class="card">
          <div class="card-header bg-white">
            <h5 class="mb-0">Business Intelligence Dashboard</h5>
          </div>
          <div class="card-body">
            <div class="row">
              <div class="col-md-4 mb-4">
                <div class="card h-100">
                  <div class="card-body text-center">
                    <h6 class="card-title text-muted">Total Reports</h6>
                    <div class="display-4 mb-2" id="totalReportsCount">-</div>
                    <div class="text-success"><i class="bi bi-file-earmark-text"></i></div>
                  </div>
                </div>
              </div>
              <div class="col-md-4 mb-4">
                <div class="card h-100">
                  <div class="card-body text-center">
                    <h6 class="card-title text-muted">Completed Projects</h6>
                    <div class="display-4 mb-2" id="completedProjectsCount">-</div>
                    <div class="text-primary"><i class="bi bi-check-circle"></i></div>
                  </div>
                </div>
              </div>
              <div class="col-md-4 mb-4">
                <div class="card h-100">
                  <div class="card-body text-center">
                    <h6 class="card-title text-muted">Active Technicians</h6>
                    <div class="display-4 mb-2" id="activeTechniciansCount">-</div>
                    <div class="text-info"><i class="bi bi-people"></i></div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="row mt-4">
              <div class="col-md-6 mb-4">
                <div class="card">
                  <div class="card-header bg-white">
                    <h6 class="mb-0">Report Status Distribution</h6>
                  </div>
                  <div class="card-body">
                    <div style="height: 250px;">
                      <canvas id="reportStatusChart"></canvas>
                    </div>
                  </div>
                </div>
              </div>
              <div class="col-md-6 mb-4">
                <div class="card">
                  <div class="card-header bg-white">
                    <h6 class="mb-0">Monthly Reports</h6>
                  </div>
                  <div class="card-body">
                    <div style="height: 250px;">
                      <canvas id="monthlyReportsChart"></canvas>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-header bg-white">
                    <h6 class="mb-0">Recent Reports</h6>
                  </div>
                  <div class="card-body">
                    <div class="table-responsive">
                      <table class="table table-hover" id="recentReportsTable">
                        <thead>
                          <tr>
                            <th>Client</th>
                            <th>Location</th>
                            <th>Date</th>
                            <th>Technician</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            <td colspan="5" class="text-center">Loading...</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Load dashboard data after a small delay to ensure the DOM is ready
  setTimeout(() => {
    loadDashboardData();
  }, 100);
}

/**
 * Load dashboard data
 */
async function loadDashboardData() {
  try {
    // In a real app, you'd fetch this data from Firebase
    // For now, we'll use placeholder data
    
    // Update counters with placeholder data
    document.getElementById('totalReportsCount').textContent = '126';
    document.getElementById('completedProjectsCount').textContent = '87';
    document.getElementById('activeTechniciansCount').textContent = '12';
    
    // Load Chart.js script
    await loadChartJS();
    
    // Create charts
    createStatusChart();
    createMonthlyChart();
    
    // Load recent reports
    loadRecentReports();
    
  } catch (error) {
    console.error('Error loading dashboard data:', error);
  }
}

/**
 * Load Chart.js library
 */
function loadChartJS() {
  return new Promise((resolve, reject) => {
    if (window.Chart) {
      resolve();
      return;
    }
    
    console.log('Loading Chart.js from CDN');
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js';
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('Failed to load Chart.js'));
    document.head.appendChild(script);
  });
}

/**
 * Create status distribution chart
 */
function createStatusChart() {
  const ctx = document.getElementById('reportStatusChart');
  if (!ctx) {
    console.error('Cannot find reportStatusChart canvas element');
    return;
  }
  
  const chart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['Submitted', 'Reviewed', 'Approved'],
      datasets: [{
        data: [38, 24, 64],
        backgroundColor: [
          '#0d6efd',
          '#0dcaf0',
          '#198754'
        ]
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          position: 'bottom'
        }
      }
    }
  });
}

/**
 * Create monthly reports chart
 */
function createMonthlyChart() {
  const ctx = document.getElementById('monthlyReportsChart');
  if (!ctx) {
    console.error('Cannot find monthlyReportsChart canvas element');
    return;
  }
  
  const chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      datasets: [{
        label: 'Reports',
        data: [12, 19, 15, 8, 13, 17, 20, 16, 9, 11, 14, 12],
        backgroundColor: '#0d6efd'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true
        }
      }
    }
  });
}

/**
 * Load recent reports
 */
function loadRecentReports() {
  // In a real app, you'd fetch this data from Firebase
  // For now, we'll use placeholder data
  
  const recentReportsData = [
    { client: 'ABC Corporation', location: 'Tunis, Downtown', date: '2023-04-15', technician: 'Ahmed Ben Ali', status: 'approved' },
    { client: 'TechSoft Inc.', location: 'Sousse, Industrial Zone', date: '2023-04-12', technician: 'Mohamed Trabelsi', status: 'reviewed' },
    { client: 'Global Solutions', location: 'Sfax, Tech Park', date: '2023-04-10', technician: 'Lina Mejri', status: 'submitted' },
    { client: 'DataNet Systems', location: 'Tunis, Lac 2', date: '2023-04-05', technician: 'Ahmed Ben Ali', status: 'approved' },
    { client: 'Smart Connect', location: 'Monastir, Commercial Center', date: '2023-04-01', technician: 'Sami Khediri', status: 'approved' }
  ];
  
  const tableBody = document.querySelector('#recentReportsTable tbody');
  if (!tableBody) {
    console.error('Cannot find recentReportsTable tbody element');
    return;
  }
  
  tableBody.innerHTML = recentReportsData.map(report => {
    const statusClass = {
      submitted: 'bg-primary',
      reviewed: 'bg-info',
      approved: 'bg-success'
    }[report.status];
    
    return `
      <tr>
        <td>${report.client}</td>
        <td>${report.location}</td>
        <td>${new Date(report.date).toLocaleDateString('fr-FR')}</td>
        <td>${report.technician}</td>
        <td><span class="badge ${statusClass}">${report.status.toUpperCase()}</span></td>
      </tr>
    `;
  }).join('');
}