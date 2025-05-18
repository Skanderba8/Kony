// src/bi/services/analytics.js
import { 
  fetchReportData, 
  fetchUserData, 
  calculateReportsByStatus,
  calculateReportsByTechnician,
  calculateReportTimelines,
  calculateComponentStatistics,
  calculateKPIs,
  getReportsTimeSeries
} from './data-processing.js';

// Cache for data to avoid redundant fetches
let dataCache = {
  reports: null,
  users: null,
  lastFetched: null,
  isLoading: false
};

// Refresh cache if older than 5 minutes
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Main analytics function
export async function getBusinessAnalytics(forceRefresh = false) {
  // Check if we need to refresh the cache
  const now = new Date();
  const cacheExpired = !dataCache.lastFetched || 
    (now - dataCache.lastFetched > CACHE_DURATION);
  
  if ((cacheExpired || forceRefresh) && !dataCache.isLoading) {
    try {
      dataCache.isLoading = true;
      
      // Fetch fresh data
      const [reports, users] = await Promise.all([
        fetchReportData(),
        fetchUserData()
      ]);
      
      dataCache = {
        reports,
        users,
        lastFetched: now,
        isLoading: false
      };
    } catch (error) {
      dataCache.isLoading = false;
      throw error;
    }
  }
  
  // If data is being loaded for the first time, wait
  if (!dataCache.reports) {
    throw new Error('Data is still loading. Please try again.');
  }
  
  // Process the data
  const analytics = {
    kpis: calculateKPIs(dataCache.reports, dataCache.users),
    reportsByStatus: calculateReportsByStatus(dataCache.reports),
    reportsByTechnician: calculateReportsByTechnician(dataCache.reports),
    reportTimelines: calculateReportTimelines(dataCache.reports),
    componentStats: calculateComponentStatistics(dataCache.reports),
    timeSeries: getReportsTimeSeries(dataCache.reports, 'month')
  };
  
  return analytics;
}

// Get filtered analytics
export async function getFilteredAnalytics(filters) {
  // Ensure we have base data
  if (!dataCache.reports) {
    await getBusinessAnalytics();
  }
  
  // Apply filters to cached data
  let filteredReports = [...dataCache.reports];
  
  if (filters.status) {
    filteredReports = filteredReports.filter(r => r.status === filters.status);
  }
  
  if (filters.technician) {
    filteredReports = filteredReports.filter(r => r.technicianName === filters.technician);
  }
  
  if (filters.client) {
    filteredReports = filteredReports.filter(r => r.clientName === filters.client);
  }
  
  if (filters.startDate) {
    const startDate = new Date(filters.startDate);
    filteredReports = filteredReports.filter(r => r.createdAt >= startDate);
  }
  
  if (filters.endDate) {
    const endDate = new Date(filters.endDate);
    filteredReports = filteredReports.filter(r => r.createdAt <= endDate);
  }
  
  // Process the filtered data
  const analytics = {
    kpis: calculateKPIs(filteredReports, dataCache.users),
    reportsByStatus: calculateReportsByStatus(filteredReports),
    reportsByTechnician: calculateReportsByTechnician(filteredReports),
    reportTimelines: calculateReportTimelines(filteredReports),
    componentStats: calculateComponentStatistics(filteredReports),
    timeSeries: getReportsTimeSeries(filteredReports, filters.timeInterval || 'month')
  };
  
  return analytics;
}

// Get technician performance analytics
export async function getTechnicianPerformance() {
  // Ensure we have base data
  if (!dataCache.reports) {
    await getBusinessAnalytics();
  }
  
  const technicianData = {};
  
  // Group reports by technician
  const reportsByTech = calculateReportsByTechnician(dataCache.reports);
  
  // Calculate performance metrics for each technician
  Object.entries(reportsByTech).forEach(([techName, reports]) => {
    // Skip empty technician names
    if (!techName) return;
    
    const submittedReports = reports.filter(r => r.submittedAt);
    const avgCompletionDays = submittedReports.length > 0 ? 
      submittedReports.reduce((sum, r) => {
        return sum + ((r.submittedAt - r.createdAt) / (1000 * 60 * 60 * 24));
      }, 0) / submittedReports.length : 0;
    
    // Count components per technician
    let componentCount = 0;
    reports.forEach(report => {
      if (!report.floors) return;
      
      report.floors.forEach(floor => {
        const componentTypes = [
          'networkCabinets', 'perforations', 'accessTraps', 'cablePaths',
          'cableTrunkings', 'conduits', 'copperCablings', 'fiberOpticCablings',
          'customComponents'
        ];
        
        componentTypes.forEach(type => {
          if (floor[type] && Array.isArray(floor[type])) {
            componentCount += floor[type].length;
          }
        });
      });
    });
    
    // Calculate status breakdown
    const statusCounts = {
      draft: reports.filter(r => r.status === 'draft').length,
      submitted: reports.filter(r => r.status === 'submitted').length,
      reviewed: reports.filter(r => r.status === 'reviewed').length,
      approved: reports.filter(r => r.status === 'approved').length
    };
    
    technicianData[techName] = {
      totalReports: reports.length,
      statusCounts,
      avgCompletionDays: Math.round(avgCompletionDays * 10) / 10,
      componentsDocumented: componentCount,
      avgComponentsPerReport: reports.length > 0 ? Math.round((componentCount / reports.length) * 10) / 10 : 0,
      mostRecentReport: reports.reduce((latest, r) => 
        !latest || r.createdAt > latest.createdAt ? r : latest, null)
    };
  });
  
  return technicianData;
}