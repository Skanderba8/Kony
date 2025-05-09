// src/utils/pdf.js - Enhanced Version with debugging and improved blob handling
import { jsPDF } from 'jspdf';
import { getReportById } from './api.js';

/**
 * Generate a comprehensive PDF for a technical visit report
 * with detailed logging for troubleshooting
 */
export async function generateReportPdf(reportId) {
  try {
    console.time('PDF Generation');
    console.log(`Starting PDF generation for report: ${reportId}`);
    
    console.log('Fetching report data...');
    // Get report data
    const report = await getReportById(reportId);
    console.log(`Report data received: ${Object.keys(report).length} fields`);
    console.log(`Report has ${report.floors?.length || 0} floors`);
    
    // Log component counts for debugging
    if (report.floors && report.floors.length > 0) {
      console.log('Floor component counts:');
      let totalComponents = 0;
      report.floors.forEach((floor, index) => {
        const networkCabinets = floor.networkCabinets?.length || 0;
        const perforations = floor.perforations?.length || 0;
        const accessTraps = floor.accessTraps?.length || 0;
        const cablePaths = floor.cablePaths?.length || 0;
        const cableTrunkings = floor.cableTrunkings?.length || 0;
        const conduits = floor.conduits?.length || 0;
        const copperCablings = floor.copperCablings?.length || 0;
        const fiberOpticCablings = floor.fiberOpticCablings?.length || 0;
        
        const floorTotal = networkCabinets + perforations + accessTraps + 
                          cablePaths + cableTrunkings + conduits + 
                          copperCablings + fiberOpticCablings;
        
        totalComponents += floorTotal;
        
        console.log(`Floor ${index + 1} (${floor.name}): ${floorTotal} components`);
        if (floorTotal > 0) {
          console.log(`  - Network Cabinets: ${networkCabinets}`);
          console.log(`  - Perforations: ${perforations}`);
          console.log(`  - Access Traps: ${accessTraps}`);
          console.log(`  - Cable Paths: ${cablePaths}`);
          console.log(`  - Cable Trunkings: ${cableTrunkings}`);
          console.log(`  - Conduits: ${conduits}`);
          console.log(`  - Copper Cablings: ${copperCablings}`);
          console.log(`  - Fiber Optic Cablings: ${fiberOpticCablings}`);
        }
      });
      console.log(`Total components across all floors: ${totalComponents}`);
    }
    
    console.log('Creating PDF document...');
    // Create PDF with A4 format
    const pdf = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4'
    });
    
    console.log('Adding title and header...');
    // Add title and header
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(16);
    pdf.text("RAPPORT DE VISITE TECHNIQUE", 15, 20);
    
    pdf.setFontSize(12);
    pdf.text("Kony - Solutions Réseaux Professionnelles", 15, 28);
    
    console.log('Adding basic information section...');
    // Add basic information section
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(14);
    pdf.text("Informations Générales", 15, 40);
    
    pdf.setDrawColor(200, 200, 200);
    pdf.line(15, 42, 195, 42);
    
    // Create general info table
    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(11);
    
    const formatDate = (dateString) => {
      if (!dateString) return 'N/A';
      const date = new Date(dateString);
      return date.toLocaleDateString('fr-FR');
    };
    
    const infoStartY = 48;
    const infoLineHeight = 7;
    
    pdf.text(`Client: ${report.clientName || 'N/A'}`, 20, infoStartY);
    pdf.text(`Lieu: ${report.location || 'N/A'}`, 20, infoStartY + infoLineHeight);
    pdf.text(`Date de visite: ${formatDate(report.date)}`, 20, infoStartY + infoLineHeight * 2);
    pdf.text(`Responsable de projet: ${report.projectManager || 'N/A'}`, 20, infoStartY + infoLineHeight * 3);
    
    const techniciansText = report.technicians?.join(', ') || 'N/A';
    pdf.text(`Techniciens: ${techniciansText}`, 20, infoStartY + infoLineHeight * 4);
    
    if (report.accompanyingPerson) {
      pdf.text(`Accompagnant: ${report.accompanyingPerson}`, 20, infoStartY + infoLineHeight * 5);
    }
    
    console.log('Adding project context section...');
    // Add project context section
    let currentY = infoStartY + (report.accompanyingPerson ? infoLineHeight * 6 : infoLineHeight * 5) + 10;
    
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(14);
    pdf.text("Contexte du Projet", 15, currentY);
    
    pdf.line(15, currentY + 2, 195, currentY + 2);
    currentY += 10;
    
    // Add context content with text wrapping
    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(11);
    
    const contextText = report.projectContext || 'Aucun contexte fourni';
    console.log(`Project context length: ${contextText.length} characters`);
    
    const splitContext = pdf.splitTextToSize(contextText, 170);
    pdf.text(splitContext, 15, currentY);
    
    currentY += splitContext.length * 6 + 10;
    
    // Add floors and components
    if (report.floors && report.floors.length > 0) {
      console.log('Processing floors and components...');
      
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(14);
      pdf.text("Composants Techniques", 15, currentY);
      pdf.line(15, currentY + 2, 195, currentY + 2);
      currentY += 10;
      
      // Loop through each floor
      for (let floorIndex = 0; floorIndex < report.floors.length; floorIndex++) {
        console.log(`Processing floor ${floorIndex + 1}...`);
        const floor = report.floors[floorIndex];
        
        // Check if we need a new page
        if (currentY > 270) {
          console.log('Adding new page for next floor');
          pdf.addPage();
          currentY = 20;
        }
        
        pdf.setFont("helvetica", "bold");
        pdf.setFontSize(12);
        pdf.text(`Étage: ${floor.name}`, 15, currentY);
        currentY += 8;
        
        console.time(`Floor ${floorIndex + 1} processing`);
        
        // Network cabinets
        if (floor.networkCabinets && floor.networkCabinets.length > 0) {
          console.log(`Processing ${floor.networkCabinets.length} network cabinets...`);
          currentY = addComponentsSection(pdf, "Baies Informatiques", floor.networkCabinets, currentY);
        }
        
        // Perforations
        if (floor.perforations && floor.perforations.length > 0) {
          console.log(`Processing ${floor.perforations.length} perforations...`);
          currentY = addComponentsSection(pdf, "Percements", floor.perforations, currentY);
        }
        
        // Access traps
        if (floor.accessTraps && floor.accessTraps.length > 0) {
          console.log(`Processing ${floor.accessTraps.length} access traps...`);
          currentY = addComponentsSection(pdf, "Trappes d'accès", floor.accessTraps, currentY);
        }
        
        // Cable paths
        if (floor.cablePaths && floor.cablePaths.length > 0) {
          console.log(`Processing ${floor.cablePaths.length} cable paths...`);
          currentY = addComponentsSection(pdf, "Chemins de câbles", floor.cablePaths, currentY);
        }
        
        // Cable trunkings
        if (floor.cableTrunkings && floor.cableTrunkings.length > 0) {
          console.log(`Processing ${floor.cableTrunkings.length} cable trunkings...`);
          currentY = addComponentsSection(pdf, "Goulottes", floor.cableTrunkings, currentY);
        }
        
        // Conduits
        if (floor.conduits && floor.conduits.length > 0) {
          console.log(`Processing ${floor.conduits.length} conduits...`);
          currentY = addComponentsSection(pdf, "Conduits", floor.conduits, currentY);
        }
        
        // Copper cablings
        if (floor.copperCablings && floor.copperCablings.length > 0) {
          console.log(`Processing ${floor.copperCablings.length} copper cablings...`);
          currentY = addComponentsSection(pdf, "Câblages cuivre", floor.copperCablings, currentY);
        }
        
        // Fiber optic cablings
        if (floor.fiberOpticCablings && floor.fiberOpticCablings.length > 0) {
          console.log(`Processing ${floor.fiberOpticCablings.length} fiber optic cablings...`);
          currentY = addComponentsSection(pdf, "Câblages fibre optique", floor.fiberOpticCablings, currentY);
        }
        
        console.timeEnd(`Floor ${floorIndex + 1} processing`);
        currentY += 5;
      }
    }
    
    console.log('Adding conclusion section...');
    // Add conclusion
    if (currentY > 240) {
      console.log('Adding new page for conclusion');
      pdf.addPage();
      currentY = 20;
    }
    
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(14);
    pdf.text("Conclusion", 15, currentY);
    pdf.line(15, currentY + 2, 195, currentY + 2);
    currentY += 10;
    
    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(11);
    
    const conclusionText = report.conclusion || 'Aucune conclusion fournie';
    console.log(`Conclusion length: ${conclusionText.length} characters`);
    
    const splitConclusion = pdf.splitTextToSize(conclusionText, 170);
    pdf.text(splitConclusion, 15, currentY);
    currentY += splitConclusion.length * 6 + 10;
    
    // Add assumptions
    if (report.assumptions && report.assumptions.length > 0) {
      console.log(`Processing ${report.assumptions.length} assumptions...`);
      
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(12);
      pdf.text("Hypothèses et prérequis:", 15, currentY);
      currentY += 8;
      
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(10);
      
      report.assumptions.forEach((assumption, index) => {
        // Check if we need a new page
        if (currentY > 270) {
          console.log('Adding new page for assumptions');
          pdf.addPage();
          currentY = 20;
        }
        
        pdf.text(`• ${assumption}`, 20, currentY);
        currentY += 6;
      });
      
      currentY += 5;
    }
    
    // Add estimated duration
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(12);
    pdf.text(`Durée estimée du déploiement: ${report.estimatedDurationDays || 'N/A'} jours`, 15, currentY);
    
    console.log('Adding page numbers and finalizing PDF...');
    // Add page numbers
    const pageCount = pdf.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      pdf.setPage(i);
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(10);
      pdf.text(`Page ${i} / ${pageCount}`, 180, 10);
      pdf.text(`Généré le ${new Date().toLocaleDateString('fr-FR')}`, 15, 287);
    }
    
    console.timeEnd('PDF Generation');
    console.log(`PDF generated with ${pageCount} pages`);
    
    // Save PDF as Blob with explicit content type
    console.log('Creating PDF blob...');
    const pdfBlob = pdf.output('blob', { type: 'application/pdf' });
    console.log('PDF blob created successfully, size:', pdfBlob.size, 'bytes');
    
    return pdfBlob;
  } catch (error) {
    console.error("Error generating PDF:", error);
    console.timeEnd('PDF Generation');
    throw error;
  }
}

/**
 * Helper function to add a component section to the PDF
 * Returns the new Y position after adding the section
 */
function addComponentsSection(pdf, title, components, currentY) {
  try {
    // Check if we need a new page
    if (currentY > 250) {
      console.log(`Adding new page for ${title} section`);
      pdf.addPage();
      currentY = 20;
    }
    
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(11);
    pdf.text(title, 20, currentY);
    currentY += 6;
    
    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(10);
    
    // Add each component
    components.forEach((component, index) => {
      try {
        // Check if we need a new page
        if (currentY > 270) {
          console.log(`Adding new page for component ${index + 1} in ${title}`);
          pdf.addPage();
          currentY = 20;
        }
        
        pdf.setFillColor(240, 240, 240);
        pdf.rect(20, currentY - 4, 175, 6, 'F');
        
        // Get component name or location for display
        const componentName = component.name || component.location || `Composant ${index + 1}`;
        pdf.text(`${index + 1}. ${componentName}`, 22, currentY);
        currentY += 6;
        
        // Get component properties
        const properties = Object.entries(component)
          .filter(([key]) => key !== 'id' && key !== 'name' && key !== 'notes')
          .map(([key, value]) => {
            try {
              // Format property name
              const formattedKey = key
                .replace(/([A-Z])/g, ' $1')
                .replace(/^./, (str) => str.toUpperCase());
              
              // Format property value
              let formattedValue = value;
              if (typeof value === 'boolean') {
                formattedValue = value ? 'Oui' : 'Non';
              } else if (typeof value === 'number') {
                if (key.toLowerCase().includes('meters')) {
                  formattedValue = `${value} m`;
                }
              } else if (value === null || value === undefined) {
                formattedValue = 'N/A';
              } else if (typeof value === 'object') {
                // Handle nested objects or arrays
                formattedValue = JSON.stringify(value);
              }
              
              return `${formattedKey}: ${formattedValue}`;
            } catch (err) {
              console.error(`Error formatting property ${key}:`, err);
              return `${key}: Error`;
            }
          });
        
        // Add properties
        properties.forEach(property => {
          try {
            if (currentY > 270) {
              pdf.addPage();
              currentY = 20;
            }
            
            pdf.text(`  • ${property}`, 22, currentY);
            currentY += 5;
          } catch (err) {
            console.error(`Error adding property to PDF:`, err);
            currentY += 5; // Still increment Y to avoid layout issues
          }
        });
        
        // Add notes if any
        if (component.notes) {
          try {
            if (currentY > 270) {
              pdf.addPage();
              currentY = 20;
            }
            
            pdf.text(`  • Notes: ${component.notes}`, 22, currentY);
            currentY += 5;
          } catch (err) {
            console.error(`Error adding notes to PDF:`, err);
            currentY += 5;
          }
        }
        
        currentY += 2;
      } catch (err) {
        console.error(`Error processing component ${index} in ${title}:`, err);
        currentY += 5; // Increment Y to avoid layout issues
      }
    });
    
    return currentY + 5;
  } catch (error) {
    console.error(`Error in addComponentsSection for ${title}:`, error);
    return currentY + 10; // Return increased Y to continue with next section
  }
}