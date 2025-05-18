// src/bi/services/report-generator.js
import { getBusinessAnalytics, getFilteredAnalytics } from './analytics.js';
import { jsPDF } from 'jspdf';
import html2canvas from 'html2canvas';
import * as XLSX from 'xlsx';

// Generate Excel report
export async function generateExcelReport(filters = {}) {
  // Get analytics data
  const analytics = filters && Object.keys(filters).length > 0 ? 
    await getFilteredAnalytics(filters) : 
    await getBusinessAnalytics();
  
  // Create workbook
  const wb = XLSX.utils.book_new();
  
  // Create KPIs worksheet
  const kpisData = [
    ['Key Performance Indicators', ''],
    ['Total Reports', analytics.kpis.totalReports],
    ['Submitted Reports', analytics.kpis.totalSubmitted],
    ['Reviewed Reports', analytics.kpis.totalReviewed],
    ['Approved Reports', analytics.kpis.totalApproved],
    ['Average Completion Time (days)', analytics.kpis.avgCompletionTime],
    ['Average Components Per Report', analytics.kpis.avgComponentsPerReport],
    ['Total Technicians', analytics.kpis.totalTechnicians],
    ['Most Active Client', analytics.kpis.mostActiveClient],
    ['Most Active Technician', analytics.kpis.mostActiveTechnician]
  ];
  const kpisWs = XLSX.utils.aoa_to_sheet(kpisData);
  XLSX.utils.book_append_sheet(wb, kpisWs, 'KPIs');
  
  // Create Reports by Status worksheet
  const statusData = [['Status', 'Count']];
  Object.entries(analytics.reportsByStatus).forEach(([status, count]) => {
    statusData.push([status, count]);
  });
  const statusWs = XLSX.utils.aoa_to_sheet(statusData);
  XLSX.utils.book_append_sheet(wb, statusWs, 'Reports by Status');
  
  // Create Reports by Technician worksheet
  const techData = [['Technician', 'Report Count']];
  Object.entries(analytics.reportsByTechnician).forEach(([tech, reports]) => {
    techData.push([tech, reports.length]);
  });
  const techWs = XLSX.utils.aoa_to_sheet(techData);
  XLSX.utils.book_append_sheet(wb, techWs, 'Reports by Technician');
  
  // Create Report Timelines worksheet
  const timelineData = [['Report ID', 'Technician', 'Client', 'Days to Submit', 'Created Date']];
  analytics.reportTimelines.forEach(item => {
    timelineData.push([
      item.id,
      item.technicianName,
      item.clientName,
      item.daysToSubmit,
      item.createdAt.toISOString().split('T')[0]
    ]);
  });
  const timelineWs = XLSX.utils.aoa_to_sheet(timelineData);
  XLSX.utils.book_append_sheet(wb, timelineWs, 'Report Timelines');
  
  // Generate Excel file
  const excelBuffer = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
  const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  
  return blob;
}

// Generate PDF report
export async function generatePdfReport(dashboardElement, title = 'Business Intelligence Report') {
  // Capture the dashboard as an image
  const canvas = await html2canvas(dashboardElement, {
    scale: 2,
    logging: false,
    useCORS: true
  });
  
  // Create PDF document
  const imgData = canvas.toDataURL('image/png');
  const imgWidth = 210; // A4 width in mm
  const pageHeight = 297; // A4 height in mm
  const imgHeight = canvas.height * imgWidth / canvas.width;
  let heightLeft = imgHeight;
  
  const doc = new jsPDF('p', 'mm', 'a4');
  let position = 0;
  
  // Add title
  doc.setFontSize(18);
  doc.text(title, 105, 15, { align: 'center' });
  doc.setFontSize(12);
  doc.text(`Generated on ${new Date().toLocaleDateString()}`, 105, 22, { align: 'center' });
  
  // Start image 30mm from top
  doc.addImage(imgData, 'PNG', 0, 30, imgWidth, imgHeight);
  heightLeft -= (pageHeight - 30);
  
  // Add additional pages if needed
  while (heightLeft >= 0) {
    position = heightLeft - imgHeight;
    doc.addPage();
    doc.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
    heightLeft -= pageHeight;
  }
  
  return doc;
}