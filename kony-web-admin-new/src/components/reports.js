// src/components/reports.js
import { getReportsByStatus, updateReportStatus, deleteReport, getReportById } from '../utils/api.js';
import { generateReportPdf } from '../utils/pdf.js';

/**
 * Affiche la liste des rapports
 */
export async function showReportsList() {
  console.log('Affichage de la liste des rapports');
  const contentContainer = document.getElementById('contentContainer');
  
  // Afficher l'état de chargement
  contentContainer.innerHTML = `
    <div class="text-center py-5">
      <div class="spinner-border text-primary" role="status"></div>
      <p class="mt-2">Chargement des rapports...</p>
    </div>
  `;
  
  // Créer l'interface utilisateur des rapports
  contentContainer.innerHTML = `
    <div class="row mb-4">
      <div class="col-12">
        <div class="card">
          <div class="card-header bg-white">
            <h5 class="mb-0">Rapports de Visite Technique</h5>
          </div>
          <div class="card-body">
            <ul class="nav nav-tabs" id="reportTabs">
              <li class="nav-item">
                <a class="nav-link active" data-status="submitted" href="#">Soumis</a>
              </li>
              <li class="nav-item">
                <a class="nav-link" data-status="reviewed" href="#">Examinés</a>
              </li>
              <li class="nav-item">
                <a class="nav-link" data-status="approved" href="#">Approuvés</a>
              </li>
            </ul>
            
            <div class="tab-content mt-3">
              <div id="reportsContainer" class="tab-pane active">
                <!-- Les rapports seront chargés ici -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Ajouter des écouteurs d'événements pour les onglets
  document.querySelectorAll('#reportTabs .nav-link').forEach(tab => {
    tab.addEventListener('click', async (e) => {
      e.preventDefault();
      
      // Mettre à jour l'onglet actif
      document.querySelectorAll('#reportTabs .nav-link').forEach(t => {
        t.classList.remove('active');
      });
      e.target.classList.add('active');
      
      // Charger les rapports
      const status = e.target.getAttribute('data-status');
      await loadReports(status);
    });
  });
  
  // Charger les rapports soumis par défaut
  await loadReports('submitted');
}

/**
 * Charger les rapports par statut
 */
async function loadReports(status) {
  const reportsContainer = document.getElementById('reportsContainer');
  
  try {
    // Afficher l'état de chargement
    reportsContainer.innerHTML = `
      <div class="text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-2">Chargement des rapports ${getStatusLabel(status).toLowerCase()}...</p>
      </div>
    `;
    
    // Récupérer les rapports
    const reports = await getReportsByStatus(status);
    
    if (reports.length === 0) {
      reportsContainer.innerHTML = `
        <div class="text-center py-5">
          <div class="display-6 text-muted">Aucun rapport ${getStatusLabel(status).toLowerCase()}</div>
          <p class="text-muted">Les rapports apparaîtront ici lorsque les techniciens les soumettront</p>
        </div>
      `;
      return;
    }
    
    // Afficher les rapports
    reportsContainer.innerHTML = reports.map(report => createReportCard(report, status)).join('');
    
    // Ajouter des écouteurs d'événements pour les actions
    reports.forEach(report => {
      // Bouton Télécharger PDF
      document.querySelector(`.download-pdf-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
        downloadReportPdf(report.id);
      });
      
      // Bouton Marquer comme examiné
      if (status === 'submitted') {
        document.querySelector(`.review-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
          updateStatus(report.id, 'reviewed');
        });
      }
      
      // Bouton Approuver
      if (status === 'reviewed') {
        document.querySelector(`.approve-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
          updateStatus(report.id, 'approved');
        });
      }
      
      // Bouton Supprimer
      document.querySelector(`.delete-btn[data-id="${report.id}"]`)?.addEventListener('click', () => {
        confirmDeleteReport(report.id);
      });
    });
  } catch (error) {
    console.error('Erreur lors du chargement des rapports:', error);
    reportsContainer.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle"></i> Erreur lors du chargement des rapports: ${error.message}
      </div>
    `;
  }
}

/**
 * Obtenir le libellé du statut en français
 */
function getStatusLabel(status) {
  switch(status) {
    case 'submitted': return 'Soumis';
    case 'reviewed': return 'Examinés';
    case 'approved': return 'Approuvés';
    default: return status;
  }
}

/**
 * Créer le HTML de la carte de rapport
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
        <h5 class="mb-0">${report.clientName || 'Rapport sans nom'}</h5>
        <span class="status-badge ${statusColorClasses[report.status] || 'bg-secondary'}">${getStatusLabel(report.status).toUpperCase()}</span>
      </div>
      <div class="card-body">
        <div class="row mb-3">
          <div class="col-md-6">
            <p><strong>Lieu:</strong> ${report.location || 'Non spécifié'}</p>
            <p><strong>Technicien:</strong> ${report.technicianName}</p>
            <p><strong>Chef de projet:</strong> ${report.projectManager || 'Non spécifié'}</p>
          </div>
          <div class="col-md-6">
            <p><strong>Date:</strong> ${new Date(report.date).toLocaleDateString('fr-FR', dateOptions)}</p>
            ${report.submittedAt ? 
              `<p><strong>Soumis le:</strong> ${new Date(report.submittedAt).toLocaleDateString('fr-FR', dateOptions)}</p>` : ''}
          </div>
        </div>
        
        <div class="d-flex justify-content-end">
          <button class="btn btn-outline-danger me-2 delete-btn" data-id="${report.id}">
            <i class="bi bi-trash"></i> Supprimer
          </button>
          <button class="btn btn-outline-primary me-2 download-pdf-btn" data-id="${report.id}">
            <i class="bi bi-download"></i> Télécharger PDF
          </button>
          ${status === 'submitted' ? 
            `<button class="btn btn-outline-info review-btn" data-id="${report.id}">
              <i class="bi bi-check-circle"></i> Marquer comme Examiné
            </button>` : ''}
          ${status === 'reviewed' ? 
            `<button class="btn btn-outline-success approve-btn" data-id="${report.id}">
              <i class="bi bi-check-all"></i> Approuver
            </button>` : ''}
        </div>
      </div>
    </div>
  `;
}

/**
 * Télécharger directement le PDF d'un rapport sans l'afficher
 */
async function downloadReportPdf(reportId) {
  try {
    // Créer et afficher un indicateur de chargement
    const loadingToast = document.createElement('div');
    loadingToast.className = 'position-fixed bottom-0 end-0 p-3';
    loadingToast.style.zIndex = '5000';
    loadingToast.innerHTML = `
      <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="toast-header">
          <strong class="me-auto">Génération du PDF</strong>
          <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Fermer"></button>
        </div>
        <div class="toast-body d-flex align-items-center">
          <div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
          <span>Préparation du PDF, veuillez patienter...</span>
        </div>
      </div>
    `;
    document.body.appendChild(loadingToast);
    
    console.log('Démarrage de la génération du PDF pour le rapport ID:', reportId);
    
    // Générer le PDF
    const pdfBlob = await generateReportPdf(reportId);
    console.log('Blob PDF généré, taille:', pdfBlob.size, 'octets');
    
    // Créer une URL pour le blob
    const pdfUrl = URL.createObjectURL(pdfBlob);
    console.log('URL PDF créée pour le téléchargement');
    
    // Créer un élément <a> pour déclencher le téléchargement
    const downloadLink = document.createElement('a');
    downloadLink.href = pdfUrl;
    downloadLink.download = `rapport-technique-${reportId}.pdf`;
    
    // Ajouter au DOM, déclencher le téléchargement et nettoyer
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
    
    // Retirer le toast de chargement
    loadingToast.remove();
    
    // Afficher un toast de succès
    const successToast = document.createElement('div');
    successToast.className = 'position-fixed bottom-0 end-0 p-3';
    successToast.style.zIndex = '5000';
    successToast.innerHTML = `
      <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="toast-header bg-success text-white">
          <strong class="me-auto">Téléchargement réussi</strong>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast" aria-label="Fermer"></button>
        </div>
        <div class="toast-body">
          Le PDF a été généré et téléchargé avec succès.
        </div>
      </div>
    `;
    document.body.appendChild(successToast);
    
    // Nettoyer l'URL du blob
    setTimeout(() => {
      URL.revokeObjectURL(pdfUrl);
      console.log('URL PDF révoquée');
      
      // Retirer le toast de succès après 3 secondes
      setTimeout(() => {
        successToast.remove();
      }, 3000);
    }, 1000);
    
  } catch (error) {
    console.error('Erreur lors de la génération ou du téléchargement du PDF:', error);
    
    // Afficher un toast d'erreur
    const errorToast = document.createElement('div');
    errorToast.className = 'position-fixed bottom-0 end-0 p-3';
    errorToast.style.zIndex = '5000';
    errorToast.innerHTML = `
      <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="toast-header bg-danger text-white">
          <strong class="me-auto">Erreur de téléchargement</strong>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast" aria-label="Fermer"></button>
        </div>
        <div class="toast-body">
          Erreur lors de la génération du PDF: ${error.message}
        </div>
      </div>
    `;
    document.body.appendChild(errorToast);
    
    // Retirer le toast d'erreur après 5 secondes
    setTimeout(() => {
      errorToast.remove();
    }, 5000);
  }
}

/**
 * Mettre à jour le statut du rapport
 */
async function updateStatus(reportId, newStatus) {
  try {
    await updateReportStatus(reportId, newStatus);
    
    // Rafraîchir la vue actuelle
    const activeTab = document.querySelector('#reportTabs .nav-link.active');
    if (activeTab) {
      await loadReports(activeTab.getAttribute('data-status'));
    }
    
    // Afficher un message de succès
    alert(`Statut du rapport mis à jour en ${getStatusLabel(newStatus).toUpperCase()}`);
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut du rapport:', error);
    alert(`Erreur lors de la mise à jour du statut du rapport: ${error.message}`);
  }
}

/**
 * Confirmer la suppression du rapport
 */
async function confirmDeleteReport(reportId) {
  if (confirm('Êtes-vous sûr de vouloir supprimer ce rapport ? Cette action ne peut pas être annulée.')) {
    try {
      await deleteReport(reportId);
      
      // Rafraîchir la vue actuelle
      const activeTab = document.querySelector('#reportTabs .nav-link.active');
      if (activeTab) {
        await loadReports(activeTab.getAttribute('data-status'));
      }
      
      // Afficher un message de succès
      alert('Rapport supprimé avec succès');
    } catch (error) {
      console.error('Erreur lors de la suppression du rapport:', error);
      alert(`Erreur lors de la suppression du rapport: ${error.message}`);
    }
  }
}