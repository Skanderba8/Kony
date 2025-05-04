// src/utils/pdf.js
import { jsPDF } from 'jspdf';
import { getReportById } from './api.js';

/**
 * Generate a simplified PDF for a report
 */
export async function generateReportPdf(reportId) {
  try {
    console.log(`Generating PDF for report: ${reportId}`);
    
    // Get report data
    const report = await getReportById(reportId);
    console.log('Report data received:', report);
    
    // Create PDF
    const pdf = new jsPDF();
    
    // Add title
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(20);
    pdf.text("RAPPORT DE VISITE TECHNIQUE", 15, 20);
    
    // Add basic information
    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(12);
    pdf.text(`Client: ${report.clientName || 'N/A'}`, 15, 40);
    pdf.text(`Location: ${report.location || 'N/A'}`, 15, 50);
    pdf.text(`Date: ${report.date ? new Date(report.date).toLocaleDateString() : 'N/A'}`, 15, 60);
    
    // Add simple report ID
    pdf.text(`Report ID: ${report.id}`, 15, 70);
    pdf.text(`Status: ${report.status}`, 15, 80);
    
    console.log('PDF generation complete');
    
    // Save PDF
    return pdf.output('blob');
  } catch (error) {
    console.error("Error generating PDF:", error);
    throw error;
  }
}