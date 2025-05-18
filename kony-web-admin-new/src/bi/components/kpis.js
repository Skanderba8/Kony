// src/bi/components/kpis.js

// Render KPI cards in a container
export function renderKPICards(containerId, kpiData) {
  const container = document.getElementById(containerId);
  
  if (!container) {
    console.error(`Container with ID ${containerId} not found`);
    return;
  }
  
  // Clear previous content
  container.innerHTML = '';
  
  // Define KPI configurations with icons, titles, and formatting
  const kpiConfigs = [
    {
      key: 'totalReports',
      title: 'Total Reports',
      icon: 'bi-file-earmark-text',
      color: 'primary',
      formatter: value => value.toString()
    },
    {
      key: 'totalSubmitted',
      title: 'Submitted',
      icon: 'bi-send',
      color: 'info',
      formatter: value => value.toString()
    },
    {
      key: 'totalReviewed',
      title: 'Reviewed',
      icon: 'bi-check2-circle',
      color: 'purple',
      formatter: value => value.toString()
    },
    {
      key: 'totalApproved',
      title: 'Approved',
      icon: 'bi-trophy',
      color: 'success',
      formatter: value => value.toString()
    },
    {
      key: 'avgCompletionTime',
      title: 'Avg. Completion Time',
      icon: 'bi-clock',
      color: 'warning',
      formatter: value => `${value} days`
    },
    {
      key: 'avgComponentsPerReport',
      title: 'Avg. Components/Report',
      icon: 'bi-diagram-3',
      color: 'indigo',
      formatter: value => value.toString()
    },
    {
      key: 'totalTechnicians',
      title: 'Technicians',
      icon: 'bi-people',
      color: 'teal',
      formatter: value => value.toString()
    },
    {
      key: 'mostActiveClient',
      title: 'Most Active Client',
      icon: 'bi-building',
      color: 'secondary',
      formatter: value => value || 'N/A'
    },
    {
      key: 'mostActiveTechnician',
      title: 'Top Technician',
      icon: 'bi-person-badge',
      color: 'dark',
      formatter: value => value || 'N/A'
    }
  ];
  
  // Create a row to hold the KPI cards
  const row = document.createElement('div');
  row.className = 'row row-cols-1 row-cols-md-3 g-4';
  
  // Create and populate KPI cards
  kpiConfigs.forEach(config => {
    const value = kpiData[config.key];
    if (value === undefined) return;
    
    const card = document.createElement('div');
    card.className = 'col';
    
    const colorClass = config.color === 'purple' ? 'bg-purple' : 
                      config.color === 'indigo' ? 'bg-indigo' :
                      config.color === 'teal' ? 'bg-teal' :
                      `bg-${config.color}`;
    
    card.innerHTML = `
      <div class="card h-100 shadow-sm">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="icon-circle ${colorClass} bg-opacity-25">
                <i class="bi ${config.icon} fs-4 text-${config.color}"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <h6 class="card-subtitle text-muted mb-1">${config.title}</h6>
              <h4 class="card-title mb-0">${config.formatter(value)}</h4>
            </div>
          </div>
        </div>
      </div>
    `;
    
    row.appendChild(card);
  });
  
  container.appendChild(row);
}