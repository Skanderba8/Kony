// src/bi/services/data-processing.js
import { db } from '../../firebase/config.js';
import { collection, getDocs, query, where, orderBy, limit } from 'firebase/firestore';
import { groupBy, sumBy, countBy, meanBy, min, max } from 'lodash';

// Main data fetching function
export async function fetchReportData(filters = {}) {
  try {
    const reportsRef = collection(db, 'technical_visit_reports');
    let q = reportsRef;
    
    // Apply filters if provided
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    if (filters.startDate && filters.endDate) {
      q = query(q, 
        where('createdAt', '>=', filters.startDate),
        where('createdAt', '<=', filters.endDate)
      );
    }
    
    // Apply sorting
    q = query(q, orderBy('createdAt', 'desc'));
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Convert timestamps to dates
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      submittedAt: doc.data().submittedAt?.toDate(),
      lastModified: doc.data().lastModified?.toDate()
    }));
  } catch (error) {
    console.error('Error fetching report data:', error);
    throw error;
  }
}

// Fetch user data
export async function fetchUserData() {
  try {
    const usersRef = collection(db, 'users');
    const snapshot = await getDocs(usersRef);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching user data:', error);
    throw error;
  }
}

// Data transformation functions
export function calculateReportsByStatus(reports) {
  return countBy(reports, 'status');
}

export function calculateReportsByTechnician(reports) {
  return groupBy(reports, 'technicianName');
}

export function calculateReportTimelines(reports) {
  const submittedReports = reports.filter(r => r.submittedAt);
  return submittedReports.map(report => {
    const creationToSubmission = report.submittedAt - report.createdAt;
    return {
      id: report.id,
      technicianName: report.technicianName,
      clientName: report.clientName,
      daysToSubmit: Math.round(creationToSubmission / (1000 * 60 * 60 * 24)),
      createdAt: report.createdAt
    };
  });
}

export function calculateComponentStatistics(reports) {
  // Extract all floor components across reports
  const allComponents = {
    networkCabinets: [],
    perforations: [],
    accessTraps: [],
    cablePaths: [],
    cableTrunkings: [],
    conduits: [],
    copperCablings: [],
    fiberOpticCablings: [],
    customComponents: []
  };
  
  reports.forEach(report => {
    if (!report.floors) return;
    
    report.floors.forEach(floor => {
      // Collect components by type
      Object.keys(allComponents).forEach(componentType => {
        if (floor[componentType] && Array.isArray(floor[componentType])) {
          allComponents[componentType].push(...floor[componentType].map(comp => ({
            ...comp,
            floorName: floor.name,
            reportId: report.id,
            clientName: report.clientName
          })));
        }
      });
    });
  });
  
  return allComponents;
}

// Calculate KPIs
export function calculateKPIs(reports, users) {
  const kpis = {
    totalReports: reports.length,
    totalSubmitted: reports.filter(r => r.status === 'submitted').length,
    totalReviewed: reports.filter(r => r.status === 'reviewed').length,
    totalApproved: reports.filter(r => r.status === 'approved').length,
    avgCompletionTime: 0,
    avgComponentsPerReport: 0,
    totalTechnicians: users.filter(u => u.role === 'technician').length,
    mostActiveClient: '',
    mostActiveTechnician: ''
  };
  
  // Calculate average completion time
  const completedReports = reports.filter(r => r.submittedAt);
  if (completedReports.length > 0) {
    const totalDays = completedReports.reduce((sum, report) => {
      const days = (report.submittedAt - report.createdAt) / (1000 * 60 * 60 * 24);
      return sum + days;
    }, 0);
    kpis.avgCompletionTime = Math.round((totalDays / completedReports.length) * 10) / 10;
  }
  
  // Calculate components per report
  let totalComponents = 0;
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
          totalComponents += floor[type].length;
        }
      });
    });
  });
  
  if (reports.length > 0) {
    kpis.avgComponentsPerReport = Math.round((totalComponents / reports.length) * 10) / 10;
  }
  
  // Find most active client
  const clientCounts = countBy(reports, 'clientName');
  let maxClientCount = 0;
  
  Object.entries(clientCounts).forEach(([client, count]) => {
    if (count > maxClientCount && client) {
      maxClientCount = count;
      kpis.mostActiveClient = client;
    }
  });
  
  // Find most active technician
  const technicianCounts = countBy(reports, 'technicianName');
  let maxTechCount = 0;
  
  Object.entries(technicianCounts).forEach(([tech, count]) => {
    if (count > maxTechCount && tech) {
      maxTechCount = count;
      kpis.mostActiveTechnician = tech;
    }
  });
  
  return kpis;
}

// Time-series data for reports creation/submission
export function getReportsTimeSeries(reports, interval = 'month') {
  // Sort reports by creation date
  const sortedReports = [...reports].sort((a, b) => a.createdAt - b.createdAt);
  
  // Group by time interval
  const timeSeriesData = {
    created: {},
    submitted: {}
  };
  
  sortedReports.forEach(report => {
    // Format date based on interval
    let createdKey, submittedKey;
    
    if (interval === 'day') {
      createdKey = report.createdAt.toISOString().split('T')[0];
      submittedKey = report.submittedAt ? report.submittedAt.toISOString().split('T')[0] : null;
    } else if (interval === 'week') {
      // Get ISO week number
      const getWeekNumber = (d) => {
        const date = new Date(d);
        date.setHours(0, 0, 0, 0);
        date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7);
        const week1 = new Date(date.getFullYear(), 0, 4);
        return 1 + Math.round(((date - week1) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
      };
      
      const createdWeek = getWeekNumber(report.createdAt);
      const createdYear = report.createdAt.getFullYear();
      createdKey = `${createdYear}-W${createdWeek}`;
      
      if (report.submittedAt) {
        const submittedWeek = getWeekNumber(report.submittedAt);
        const submittedYear = report.submittedAt.getFullYear();
        submittedKey = `${submittedYear}-W${submittedWeek}`;
      }
    } else {
      // Default to month
      createdKey = `${report.createdAt.getFullYear()}-${report.createdAt.getMonth() + 1}`;
      submittedKey = report.submittedAt ? 
        `${report.submittedAt.getFullYear()}-${report.submittedAt.getMonth() + 1}` : null;
    }
    
    // Increment counters
    if (createdKey) {
      timeSeriesData.created[createdKey] = (timeSeriesData.created[createdKey] || 0) + 1;
    }
    
    if (submittedKey) {
      timeSeriesData.submitted[submittedKey] = (timeSeriesData.submitted[submittedKey] || 0) + 1;
    }
  });
  
  // Convert to arrays for charting
  const result = {
    created: Object.entries(timeSeriesData.created).map(([date, count]) => ({ date, count })),
    submitted: Object.entries(timeSeriesData.submitted).map(([date, count]) => ({ date, count }))
  };
  
  return result;
}