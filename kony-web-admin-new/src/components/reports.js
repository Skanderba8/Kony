import { getReportsByStatus, updateReportStatus, deleteReport } from '../utils/api.js';
import { generateReportPdf } from '../utils/pdf.js';

/**
 * Shows the reports list
 */
export async function showReportsList() {
  console.log('Showing reports list');
  const contentContainer = document.getElementById('contentContainer');
  
  // Show loading state
  contentContainer.innerHTML = `
    <div class="text-center py-5">
      <div class="spinner-border text-primary" role="status"></div>
      <p class="mt-2">Loading reports...</p>
    </div>
  `;
  
  // Create reports UI
  contentContainer.innerHTML = `
    <div class="row mb-4">
      <div class="col-12">
        <div class="card">
          <div class="card-header bg-white">
            <h5 class="mb-0">Technical Visit Reports</h5>
          </div>
          <div class="card-body">
            <ul class="nav nav-tabs" id="reportTabs">
              <li class="nav-item">
                <a class="nav-link active" data-status="submitted" href="#">Submitted</a>
              </li>
              <li class="nav-item">
                <a class="nav-link" data-status="reviewed" href="#">Reviewed</a>
              </li>
              <li class="nav-item">
                <a class="nav-link" data-status="approved" href="#">Approved</a>
              </li>
            </ul>
            
            <div class="tab-content mt-3">
              <div id="reportsContainer" class="tab-pane active">
                <!-- Reports will be loaded here -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Add event listeners for tabs
  document.querySelectorAll('#reportTabs .nav-link').forEach(tab => {
    tab.addEventListener('click', async (e) => {
      e.preventDefault();
      
      // Update active tab
      document.querySelectorAll('#reportTabs .nav-link').forEach(t => {
        t.classList.remove('active');
      });
      e.target.classList.add('active');
      
      // Load reports
      const status = e.target.getAttribute('data-status');
      await loadReports(status);
    });
  });
  
  // Load submitted reports by default
  await loadReports('submitted');
}

/**
 * Load reports by status
 */
async function loadReports(status) {
  const reportsContainer = document.getElementById('reportsContainer');
  
  try {
    // Show loading state
    reportsContainer.innerHTML = `
      <div class="text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-2">Loading ${status} reports...</p>
      </div>
    `;
    
    // Fetch reports
    const reports = await getReportsByStatus(status);
    
    if (reports.length === 0) {
      reportsContainer.innerHTML = `
        <div class="text-center py-5">
          <div class="display-6 text-muted">No ${status} reports</div>
          <p class="text-muted">Reports will appear here when technicians submit them</p>
        </div>
      `;
      return;
    }
    
    // Render reports
    reportsContainer.innerHTML = reports.map(report => createReportCard(report, status)).join('');
    
    // Add event listeners for actions
    reports.forEach(report => {
      // View PDF button
      document.querySelector(`.view-pdf-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
        viewReportPdf(report.id);
      });
      
      // Mark as reviewed button
      if (status === 'submitted') {
        document.querySelector(`.review-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
          updateStatus(report.id, 'reviewed');
        });
      }
      
      // Approve button
      if (status === 'reviewed') {
        document.querySelector(`.approve-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
          updateStatus(report.id, 'approved');
        });
      }
      
      // Delete button
      document.querySelector(`.delete-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
        confirmDeleteReport(report.id);
      });
    });
  } catch (error) {
    console.error('Error loading reports:', error);
    reportsContainer.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle"></i> Error loading reports: ${error.message}
      </div>
    `;
  }
}

/**
 * Create a report card HTML
 */
function createReportCard(report, status) {
  const statusColorClasses = {
    submitted: 'bg-primary',
    reviewed: 'bg-info',
    approved: 'bg-success'
  };
  
  const dateOptions = { year: 'numeric', month: 'short', day: 'numeric' };
  
  return `
    <div class="card mb-3">
      <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0">${report.clientName || 'Unnamed Report'}</h5>
        <span class="status-badge ${statusColorClasses[report.status] || 'bg-secondary'}">${report.status.toUpperCase()}</span>
      </div>
      <div class="card-body">
        <div class="row mb-3">
          <div class="col-md-6">
            <p><strong>Location:</strong> 
            <div class="card-body">
        <div class="row mb-3">
          <div class="col-md-6">
            <p><strong>Location:</strong> ${report.location || 'Not specified'}</p>
            <p><strong>Technician:</strong> ${report.technicianName}</p>
            <p><strong>Project Manager:</strong> ${report.projectManager || 'Not specified'}</p>
          </div>
          <div class="col-md-6">
            <p><strong>Date:</strong> ${new Date(report.date).toLocaleDateString(undefined, dateOptions)}</p>
            ${report.submittedAt ? 
              `<p><strong>Submitted:</strong> ${new Date(report.submittedAt).toLocaleDateString(undefined, dateOptions)}</p>` : ''}
          </div>
        </div>
        
        <div class="d-flex justify-content-end">
          <button class="btn btn-outline-danger me-2 delete-btn" data-id="${report.id}">
            <i class="bi bi-trash"></i> Delete
          </button>
          <button class="btn btn-outline-primary me-2 view-pdf-btn" data-id="${report.id}">
            <i class="bi bi-file-pdf"></i> View PDF
          </button>
          ${status === 'submitted' ? 
            `<button class="btn btn-outline-info review-btn" data-id="${report.id}">
              <i class="bi bi-check-circle"></i> Mark as Reviewed
            </button>` : ''}
          ${status === 'reviewed' ? 
            `<button class="btn btn-outline-success approve-btn" data-id="${report.id}">
              <i class="bi bi-check-all"></i> Approve
            </button>` : ''}
        </div>
      </div>
    </div>
  `;
}

/**
 * View PDF for a report
 */
/**
 * View PDF for a report with detailed progress updates
 */
/**
 * View PDF for a report with detailed progress updates
 */
async function viewReportPdf(reportId) {
  const pdfModal = new bootstrap.Modal(document.getElementById('pdfModal'));
  const pdfViewer = document.getElementById('pdfViewer');
  
  // Progress log array to keep track of all messages
  const progressLog = [];
  
  // Function to update loading progress
  const updateProgress = (message) => {
      console.log(`PDF Progress: ${message}`);
      progressLog.push(`• ${message}`);
      
      pdfViewer.srcdoc = `
          <html>
          <body style="display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: Arial, sans-serif;">
              <div style="text-align: center; max-width: 80%;">
              <div style="border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 2s linear infinite; margin: 0 auto;"></div>
              <p style="margin-top: 20px; font-weight: bold;">PDF Generation in Progress</p>
              <p style="margin-top: 10px;">${message}</p>
              <div style="text-align: left; background: #f8f9fa; padding: 10px; border-radius: 5px; margin-top: 20px; max-height: 200px; overflow-y: auto; font-family: monospace; font-size: 12px;" id="progressLog">
                  ${progressLog.join('<br>')}
              </div>
              </div>
              <style>
              @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
              </style>
          </body>
          </html>
      `;
  };

  try {
      // Show initial loading state
      updateProgress("Initializing PDF generation...");
      pdfModal.show();
      
      // Set a timeout to detect if PDF generation is taking too long
      const timeoutId = setTimeout(() => {
          updateProgress("⚠️ PDF generation is taking longer than expected. This might indicate an issue with the data or the generation process. You can wait or try again later.");
      }, 15000); // 15 seconds timeout
      
      console.log('Starting PDF generation for report ID:', reportId);
      updateProgress("Fetching report data...");
      
      // Fetch the report data first to see if there's an issue there
      const report = await getReportById(reportId);
      console.log('Report data received:', report);
      
      // Check if report data is valid
      if (!report) {
          updateProgress("❌ Error: No report data received");
          throw new Error("Failed to fetch report data");
      }
      
      updateProgress(`Report data received (${Object.keys(report).length} fields)`);
      
      // Check if floors data is present
      if (!report.floors || report.floors.length === 0) {
          updateProgress("⚠️ Warning: No floors data found in report");
      } else {
          updateProgress(`Found ${report.floors.length} floors with data`);
          
          // Log components count for debugging
          let totalComponents = 0;
          report.floors.forEach(floor => {
              const componentsCount = (floor.networkCabinets?.length || 0) +
                                     (floor.perforations?.length || 0) +
                                     (floor.accessTraps?.length || 0) +
                                     (floor.cablePaths?.length || 0) +
                                     (floor.cableTrunkings?.length || 0) +
                                     (floor.conduits?.length || 0) +
                                     (floor.copperCablings?.length || 0) +
                                     (floor.fiberOpticCablings?.length || 0);
              totalComponents += componentsCount;
              updateProgress(`Floor "${floor.name}": ${componentsCount} components`);
          });
          updateProgress(`Total components to process: ${totalComponents}`);
      }
      
      // Generate the PDF with progress updates
      updateProgress("Creating PDF document structure...");
      
      // Track start time for performance analysis
      const startTime = performance.now();
      
      // Add periodic updates while PDF is generating
      const progressInterval = setInterval(() => {
          updateProgress(`Still generating PDF... (${((performance.now() - startTime) / 1000).toFixed(1)} seconds elapsed)`);
      }, 3000);
      
      try {
          const pdfBlob = await generateReportPdf(reportId);
          
          // Clear the progress interval
          clearInterval(progressInterval);
          
          // Calculate elapsed time
          const elapsedTime = ((performance.now() - startTime) / 1000).toFixed(2);
          console.log(`PDF generated in ${elapsedTime} seconds`);
          updateProgress(`✅ PDF generation completed in ${elapsedTime} seconds. Loading document...`);
          
          // Clear the timeout since PDF generation completed
          clearTimeout(timeoutId);
          
          console.log('PDF blob generated:', pdfBlob);
          
          const pdfUrl = URL.createObjectURL(pdfBlob);
          console.log('PDF URL created:', pdfUrl);
          
          // Short delay before loading the PDF to ensure the progress message is seen
          setTimeout(() => {
              pdfViewer.src = pdfUrl;
              console.log('PDF viewer source set');
          }, 500);
          
          // Clean up URL when modal is hidden
          document.getElementById('pdfModal').addEventListener('hidden.bs.modal', () => {
              URL.revokeObjectURL(pdfUrl);
              console.log('PDF URL revoked');
          }, { once: true });
      } catch (pdfError) {
          clearInterval(progressInterval);
          clearTimeout(timeoutId);
          
          console.error('Error generating PDF:', pdfError);
          updateProgress(`❌ Error during PDF generation: ${pdfError.message}`);
          
          // Re-throw to be caught by the outer try/catch
          throw pdfError;
      }
  } catch (error) {
      console.error('Error viewing PDF:', error);
      
      pdfViewer.srcdoc = `
          <html>
          <body style="display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: Arial, sans-serif;">
              <div style="text-align: center; color: #dc3545; max-width: 80%;">
              <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" viewBox="0 0 16 16">
                  <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"/>
                  <path d="M7.002 11a1 1 0 1 1 2 0 1 1 0 0 1-2 0zM7.1 4.995a.905.905 0 1 1 1.8 0l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 4.995z"/>
              </svg>
              <h3 style="margin-top: 20px;">Error Generating PDF</h3>
              <p>${error.message}</p>
              <div style="text-align: left; background: #f8f9fa; padding: 10px; border-radius: 5px; margin-top: 20px; overflow: auto; max-height: 300px;">
                  <pre style="margin: 0; white-space: pre-wrap;">${error.stack}</pre>
              </div>
              <div style="margin-top: 20px;">
                  <button onclick="window.location.reload()" style="padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;">Try Again</button>
              </div>
              </div>
          </body>
          </html>
      `;
  }
}