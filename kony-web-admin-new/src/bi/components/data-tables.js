    // src/bi/components/data-tables.js

// Create a sortable data table
export function createDataTable(containerId, data, columns, options = {}) {
  const container = document.getElementById(containerId);
  
  if (!container) {
    console.error(`Container with ID ${containerId} not found`);
    return;
  }
  
  // Clear previous content
  container.innerHTML = '';
  
  // Create the table element
  const table = document.createElement('table');
  table.className = options.tableClass || 'table table-striped table-hover table-sm';
  
  // Create table header
  const thead = document.createElement('thead');
  const headerRow = document.createElement('tr');
  
  columns.forEach(column => {
    const th = document.createElement('th');
    th.textContent = column.title;
    
    if (column.sortable) {
      th.classList.add('sortable');
      th.addEventListener('click', () => sortTable(table, column.field));
    }
    
    if (column.width) {
      th.style.width = column.width;
    }
    
    headerRow.appendChild(th);
  });
  
  thead.appendChild(headerRow);
  table.appendChild(thead);
  
  // Create table body
  const tbody = document.createElement('tbody');
  
  // Add data rows
  data.forEach(item => {
    const row = document.createElement('tr');
    
    columns.forEach(column => {
      const cell = document.createElement('td');
      
      // Get cell value using field accessor
      let value = item[column.field];
      
      // Apply formatter if provided
      if (column.formatter) {
        value = column.formatter(value, item);
      }
      
      // Set cell content
      if (column.html) {
        cell.innerHTML = value;
      } else {
        cell.textContent = value;
      }
      
      // Add custom classes if specified
      if (column.cellClass) {
        cell.className = column.cellClass;
      }
      
      row.appendChild(cell);
    });
    
    // Add row click handler if provided
    if (options.onRowClick) {
      row.style.cursor = 'pointer';
      row.addEventListener('click', () => options.onRowClick(item));
    }
    
    tbody.appendChild(row);
  });
  
  table.appendChild(tbody);
  
  // Create table wrapper with optional caption/title
  const wrapper = document.createElement('div');
  wrapper.className = 'table-responsive mb-4';
  
  if (options.title) {
    const title = document.createElement('h5');
    title.className = 'mb-3';
    title.textContent = options.title;
    wrapper.appendChild(title);
  }
  
  wrapper.appendChild(table);
  container.appendChild(wrapper);
  
  // Initialize table pagination if needed
  if (options.pagination && data.length > options.pagination.rowsPerPage) {
    createTablePagination(wrapper, table, options.pagination);
  }
  
  return table;
}

// Sort table by column
function sortTable(table, field) {
  const tbody = table.querySelector('tbody');
  const rows = Array.from(tbody.querySelectorAll('tr'));
  const headers = table.querySelectorAll('th.sortable');
  
  // Find the header element for this field
  const headerEl = Array.from(headers).find(th => 
    th.textContent.toLowerCase() === field.toLowerCase() ||
    th.dataset.field === field
  );
  
  if (!headerEl) return;
  
  // Toggle sort direction
  const currentDir = headerEl.dataset.sortDirection || 'asc';
  const newDir = currentDir === 'asc' ? 'desc' : 'asc';
  
  // Reset all headers
  headers.forEach(th => {
    th.dataset.sortDirection = '';
    th.classList.remove('sorted-asc', 'sorted-desc');
  });
  
  // Set new sort direction
  headerEl.dataset.sortDirection = newDir;
  headerEl.classList.add(`sorted-${newDir}`);
  
  // Sort the rows
  rows.sort((a, b) => {
    const aValue = getCellValue(a, field);
    const bValue = getCellValue(b, field);
    
    // Compare values
    if (aValue < bValue) return newDir === 'asc' ? -1 : 1;
    if (aValue > bValue) return newDir === 'asc' ? 1 : -1;
    return 0;
  });
  
  // Reorder rows
  rows.forEach(row => tbody.appendChild(row));
}

// Get cell value for sorting
function getCellValue(row, field) {
  const cells = row.querySelectorAll('td');
  const index = Array.from(row.parentNode.parentNode.querySelector('thead tr').cells)
    .findIndex(cell => cell.textContent.toLowerCase() === field.toLowerCase() || cell.dataset.field === field);
  
  if (index === -1) return '';
  
  const cell = cells[index];
  return cell.textContent.trim();
}

// Create pagination for a table
function createTablePagination(wrapper, table, options) {
  const tbody = table.querySelector('tbody');
  const rows = Array.from(tbody.querySelectorAll('tr'));
  const rowsPerPage = options.rowsPerPage || 10;
  const totalPages = Math.ceil(rows.length / rowsPerPage);
  
  let currentPage = 1;
  
  // Create pagination container
  const paginationEl = document.createElement('nav');
  paginationEl.setAttribute('aria-label', 'Table pagination');
  paginationEl.className = 'mt-3';
  
  // Create pagination logic
  function showPage(page) {
    currentPage = page;
    
    // Hide all rows
    rows.forEach(row => row.style.display = 'none');
    
    // Show rows for current page
    const startIndex = (page - 1) * rowsPerPage;
    const endIndex = Math.min(startIndex + rowsPerPage, rows.length);
    
    for (let i = startIndex; i < endIndex; i++) {
      rows[i].style.display = '';
    }
    
    // Update pagination UI
    updatePagination();
  }
  
  // Update pagination links
  function updatePagination() {
    // Create pagination list
    const ul = document.createElement('ul');
    ul.className = 'pagination pagination-sm justify-content-end';
    
    // Previous button
    const prevLi = document.createElement('li');
    prevLi.className = `page-item ${currentPage === 1 ? 'disabled' : ''}`;
    
    const prevLink = document.createElement('a');
    prevLink.className = 'page-link';
    prevLink.href = '#';
    prevLink.setAttribute('aria-label', 'Previous');
    prevLink.innerHTML = '<span aria-hidden="true">&laquo;</span>';
    prevLink.addEventListener('click', e => {
      e.preventDefault();
      if (currentPage > 1) showPage(currentPage - 1);
    });
    
    prevLi.appendChild(prevLink);
    ul.appendChild(prevLi);
    
    // Page links
    const maxVisiblePages = 5;
    let startPage = Math.max(currentPage - Math.floor(maxVisiblePages / 2), 1);
    let endPage = Math.min(startPage + maxVisiblePages - 1, totalPages);
    
    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = Math.max(endPage - maxVisiblePages + 1, 1);
    }
    
    for (let i = startPage; i <= endPage; i++) {
      const li = document.createElement('li');
      li.className = `page-item ${i === currentPage ? 'active' : ''}`;
      
      const link = document.createElement('a');
      link.className = 'page-link';
      link.href = '#';
      link.textContent = i;
      link.addEventListener('click', e => {
        e.preventDefault();
        showPage(i);
      });
      
      li.appendChild(link);
      ul.appendChild(li);
    }
    
    // Next button
    const nextLi = document.createElement('li');
    nextLi.className = `page-item ${currentPage === totalPages ? 'disabled' : ''}`;
    
    const nextLink = document.createElement('a');
    nextLink.className = 'page-link';
    nextLink.href = '#';
    nextLink.setAttribute('aria-label', 'Next');
    nextLink.innerHTML = '<span aria-hidden="true">&raquo;</span>';
    nextLink.addEventListener('click', e => {
      e.preventDefault();
      if (currentPage < totalPages) showPage(currentPage + 1);
    });
    
    nextLi.appendChild(nextLink);
    ul.appendChild(nextLi);
    
    // Update pagination element
    paginationEl.innerHTML = '';
    paginationEl.appendChild(ul);
  }
  
  // Show first page and append pagination
  wrapper.appendChild(paginationEl);
  showPage(1);
}

// Create a data table specifically for technician performance
export function createTechnicianTable(containerId, technicianData) {
  const tableData = Object.entries(technicianData).map(([name, data]) => ({
    name,
    totalReports: data.totalReports,
    submitted: data.statusCounts.submitted,
    reviewed: data.statusCounts.reviewed,
    approved: data.statusCounts.approved,
    avgDays: data.avgCompletionDays,
    components: data.componentsDocumented,
    avgComponents: data.avgComponentsPerReport,
    mostRecent: data.mostRecentReport ? new Date(data.mostRecentReport.createdAt) : null
  }));
  
  const columns = [
    { field: 'name', title: 'Technician', sortable: true },
    { field: 'totalReports', title: 'Total Reports', sortable: true },
    { field: 'submitted', title: 'Submitted', sortable: true },
    { field: 'reviewed', title: 'Reviewed', sortable: true },
    { field: 'approved', title: 'Approved', sortable: true },
    { 
      field: 'avgDays', 
      title: 'Avg. Days to Submit', 
      sortable: true,
      formatter: value => value.toFixed(1)
    },
    { field: 'components', title: 'Components', sortable: true },
    { 
      field: 'avgComponents', 
      title: 'Avg. Components', 
      sortable: true,
      formatter: value => value.toFixed(1)
    },
    { 
      field: 'mostRecent', 
      title: 'Most Recent', 
      sortable: true,
      formatter: value => value ? value.toLocaleDateString() : 'N/A'
    }
  ];
  
  return createDataTable(containerId, tableData, columns, {
    title: 'Technician Performance Metrics',
    pagination: { rowsPerPage: 5 }
  });
}

// Create a report summary table
export function createReportSummaryTable(containerId, reports) {
  const tableData = reports.map(report => ({
    id: report.id,
    clientName: report.clientName || 'Unknown',
    technicianName: report.technicianName || 'Unknown',
    status: report.status,
    createdAt: new Date(report.createdAt),
    submittedAt: report.submittedAt ? new Date(report.submittedAt) : null,
    components: calculateTotalComponents(report),
    location: report.location || 'Unknown'
  }));
  
  const columns = [
    { field: 'clientName', title: 'Client', sortable: true },
    { field: 'technicianName', title: 'Technician', sortable: true },
    { 
      field: 'status', 
      title: 'Status', 
      sortable: true,
      formatter: value => {
        const status = value.charAt(0).toUpperCase() + value.slice(1);
        let badgeClass = 'secondary';
        
        switch(value) {
          case 'draft': badgeClass = 'secondary'; break;
          case 'submitted': badgeClass = 'primary'; break;
          case 'reviewed': badgeClass = 'info'; break;
          case 'approved': badgeClass = 'success'; break;
        }
        
        return `<span class="badge bg-${badgeClass}">${status}</span>`;
      },
      html: true
    },
    { 
      field: 'createdAt', 
      title: 'Created', 
      sortable: true,
      formatter: value => value.toLocaleDateString()
    },
    { 
      field: 'submittedAt', 
      title: 'Submitted', 
      sortable: true,
      formatter: value => value ? value.toLocaleDateString() : 'Not submitted'
    },
    { field: 'components', title: 'Components', sortable: true },
    { field: 'location', title: 'Location', sortable: true }
  ];
  
  return createDataTable(containerId, tableData, columns, {
    title: 'Recent Reports',
    pagination: { rowsPerPage: 10 },
    onRowClick: report => showReportDetails(report.id)
  });
}

// Helper function to calculate total components in a report
function calculateTotalComponents(report) {
  if (!report.floors) return 0;
  
  let total = 0;
  const componentTypes = [
    'networkCabinets', 'perforations', 'accessTraps', 'cablePaths',
    'cableTrunkings', 'conduits', 'copperCablings', 'fiberOpticCablings',
    'customComponents'
  ];
  
  report.floors.forEach(floor => {
    componentTypes.forEach(type => {
      if (floor[type] && Array.isArray(floor[type])) {
        total += floor[type].length;
      }
    });
  });
  
  return total;
}

// Show report details (placeholder - to be implemented in main dashboard)
function showReportDetails(reportId) {
  console.log(`Showing details for report: ${reportId}`);
  // This will be implemented in the main dashboard.js
}