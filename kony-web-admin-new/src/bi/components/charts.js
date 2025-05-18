// src/bi/components/charts.js
import Chart from 'chart.js/auto';
import * as echarts from 'echarts';

// Create and render a Chart.js chart
export function createChartJsChart(canvasId, config) {
  const ctx = document.getElementById(canvasId).getContext('2d');
  return new Chart(ctx, config);
}

// Create and render an ECharts chart
export function createEChartInstance(elementId, options) {
  const chartElement = document.getElementById(elementId);
  const chart = echarts.init(chartElement);
  chart.setOption(options);
  
  // Handle resize
  window.addEventListener('resize', () => {
    chart.resize();
  });
  
  return chart;
}

// Render report status pie chart
export function renderStatusPieChart(elementId, data) {
  const labels = Object.keys(data).map(key => {
    // Make status labels more readable
    switch(key) {
      case 'draft': return 'Draft';
      case 'submitted': return 'Submitted';
      case 'reviewed': return 'Reviewed';
      case 'approved': return 'Approved';
      default: return key.charAt(0).toUpperCase() + key.slice(1);
    }
  });
  
  const values = Object.values(data);
  
  const chartConfig = {
    type: 'pie',
    data: {
      labels: labels,
      datasets: [{
        data: values,
        backgroundColor: [
          'rgba(108, 117, 125, 0.8)',  // gray for draft
          'rgba(0, 123, 255, 0.8)',    // blue for submitted
          'rgba(111, 66, 193, 0.8)',   // purple for reviewed
          'rgba(40, 167, 69, 0.8)'     // green for approved
        ],
        borderColor: [
          'rgba(108, 117, 125, 1)',
          'rgba(0, 123, 255, 1)',
          'rgba(111, 66, 193, 1)',
          'rgba(40, 167, 69, 1)'
        ],
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'right',
        },
        title: {
          display: true,
          text: 'Reports by Status'
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              const label = context.label || '';
              const value = context.raw || 0;
              const total = context.dataset.data.reduce((a, b) => a + b, 0);
              const percentage = Math.round((value / total) * 100);
              return `${label}: ${value} (${percentage}%)`;
            }
          }
        }
      }
    }
  };
  
  return createChartJsChart(elementId, chartConfig);
}

// Render technician performance chart
export function renderTechnicianChart(elementId, technicianData) {
  const techNames = Object.keys(technicianData);
  const reportCounts = techNames.map(name => technicianData[name].totalReports);
  const avgCompletionDays = techNames.map(name => technicianData[name].avgCompletionDays);
  const componentsPerReport = techNames.map(name => technicianData[name].avgComponentsPerReport);
  
  const chartConfig = {
    type: 'bar',
    data: {
      labels: techNames,
      datasets: [
        {
          label: 'Total Reports',
          data: reportCounts,
          backgroundColor: 'rgba(0, 123, 255, 0.7)',
          borderColor: 'rgba(0, 123, 255, 1)',
          borderWidth: 1,
          yAxisID: 'y'
        },
        {
          label: 'Avg. Completion Days',
          data: avgCompletionDays,
          backgroundColor: 'rgba(255, 193, 7, 0.7)',
          borderColor: 'rgba(255, 193, 7, 1)',
          borderWidth: 1,
          yAxisID: 'y1'
        },
        {
          label: 'Avg. Components per Report',
          data: componentsPerReport,
          backgroundColor: 'rgba(40, 167, 69, 0.7)',
          borderColor: 'rgba(40, 167, 69, 1)',
          borderWidth: 1,
          yAxisID: 'y2'
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'top',
        },
        title: {
          display: true,
          text: 'Technician Performance Metrics'
        }
      },
      scales: {
        y: {
          type: 'linear',
          display: true,
          position: 'left',
          title: {
            display: true,
            text: 'Reports'
          }
        },
        y1: {
          type: 'linear',
          display: true,
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
          title: {
            display: true,
            text: 'Days'
          }
        },
        y2: {
          type: 'linear',
          display: true,
          position: 'right',
          grid: {
            drawOnChartArea: false,
          },
          title: {
            display: true,
            text: 'Components'
          }
        }
      }
    }
  };
  
  return createChartJsChart(elementId, chartConfig);
}

// Render time series chart
export function renderTimeSeriesChart(elementId, timeSeriesData) {
  // Prepare data
  const allDates = new Set([
    ...timeSeriesData.created.map(item => item.date),
    ...timeSeriesData.submitted.map(item => item.date)
  ]);
  
  const sortedDates = [...allDates].sort();
  
  // Create lookup maps
  const createdMap = new Map(timeSeriesData.created.map(item => [item.date, item.count]));
  const submittedMap = new Map(timeSeriesData.submitted.map(item => [item.date, item.count]));
  
  // Prepare labels and datasets
  const labels = sortedDates;
  const createdData = sortedDates.map(date => createdMap.get(date) || 0);
  const submittedData = sortedDates.map(date => submittedMap.get(date) || 0);
  
  // Format date labels
  const formattedLabels = labels.map(date => {
    if (date.includes('-W')) {
      // Week format
      const [year, week] = date.split('-W');
      return `Week ${week}, ${year}`;
    } else if (date.includes('-')) {
      // Handle YYYY-MM or YYYY-MM-DD
      const parts = date.split('-');
      if (parts.length === 2) {
        // Month format
        return new Date(parts[0], parts[1] - 1, 1).toLocaleDateString(undefined, {
          year: 'numeric',
          month: 'short'
        });
      } else {
        // Day format
        return new Date(date).toLocaleDateString(undefined, {
          year: 'numeric',
          month: 'short',
          day: 'numeric'
        });
      }
    }
    return date;
  });
  
  const chartConfig = {
    type: 'line',
    data: {
      labels: formattedLabels,
      datasets: [
        {
          label: 'Reports Created',
          data: createdData,
          borderColor: 'rgba(0, 123, 255, 1)',
          backgroundColor: 'rgba(0, 123, 255, 0.1)',
          fill: true,
          tension: 0.3
        },
        {
// src/bi/components/charts.js (continued)
          label: 'Reports Submitted',
          data: submittedData,
          borderColor: 'rgba(40, 167, 69, 1)',
          backgroundColor: 'rgba(40, 167, 69, 0.1)',
          fill: true,
          tension: 0.3
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'top',
        },
        title: {
          display: true,
          text: 'Report Creation & Submission Trends'
        },
        tooltip: {
          mode: 'index',
          intersect: false
        }
      },
      scales: {
        x: {
          grid: {
            display: false
          }
        },
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Number of Reports'
          }
        }
      }
    }
  };
  
  return createChartJsChart(elementId, chartConfig);
}

// Render component distribution chart
export function renderComponentDistributionChart(elementId, componentStats) {
  // Count components by type
  const componentCounts = {};
  Object.entries(componentStats).forEach(([type, components]) => {
    componentCounts[type] = components.length;
  });
  
  // Format type names for better readability
  const formattedTypes = {
    networkCabinets: 'Network Cabinets',
    perforations: 'Perforations',
    accessTraps: 'Access Traps',
    cablePaths: 'Cable Paths',
    cableTrunkings: 'Cable Trunkings',
    conduits: 'Conduits',
    copperCablings: 'Copper Cablings',
    fiberOpticCablings: 'Fiber Optic Cablings',
    customComponents: 'Custom Components'
  };
  
  const chartOptions = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'value'
    },
    yAxis: {
      type: 'category',
      data: Object.keys(componentCounts).map(type => formattedTypes[type] || type),
      axisLabel: {
        interval: 0,
        width: 80,
        overflow: 'truncate'
      }
    },
    series: [
      {
        name: 'Count',
        type: 'bar',
        data: Object.values(componentCounts),
        itemStyle: {
          color: function(params) {
            const colors = [
              '#5470c6', '#91cc75', '#fac858', '#ee6666',
              '#73c0de', '#3ba272', '#fc8452', '#9a60b4',
              '#ea7ccc'
            ];
            return colors[params.dataIndex % colors.length];
          }
        },
        label: {
          show: true,
          position: 'right'
        }
      }
    ]
  };
  
  return createEChartInstance(elementId, chartOptions);
}

// Render heatmap for component distribution by floor
export function renderComponentHeatmap(elementId, componentStats) {
  // Process data to get component counts by floor
  const floorComponentMap = new Map();
  const componentTypes = Object.keys(componentStats);
  
  componentTypes.forEach(type => {
    componentStats[type].forEach(component => {
      if (!component.floorName) return;
      
      const key = `${component.reportId}-${component.floorName}`;
      if (!floorComponentMap.has(key)) {
        floorComponentMap.set(key, {
          report: component.reportId,
          floor: component.floorName,
          client: component.clientName || 'Unknown',
          counts: Object.fromEntries(componentTypes.map(t => [t, 0]))
        });
      }
      
      floorComponentMap.get(key).counts[type]++;
    });
  });
  
  // Convert to array and sort by total components
  const floorData = Array.from(floorComponentMap.values());
  floorData.sort((a, b) => {
    const aTotal = Object.values(a.counts).reduce((sum, count) => sum + count, 0);
    const bTotal = Object.values(b.counts).reduce((sum, count) => sum + count, 0);
    return bTotal - aTotal;
  });
  
  // Take top 15 floors by component count
  const topFloors = floorData.slice(0, 15);
  
  // Prepare heatmap data
  const yAxisData = topFloors.map(d => `${d.client} - ${d.floor}`);
  const xAxisData = componentTypes.map(type => {
    const formattedTypes = {
      networkCabinets: 'Network Cabinets',
      perforations: 'Perforations',
      accessTraps: 'Access Traps',
      cablePaths: 'Cable Paths',
      cableTrunkings: 'Cable Trunkings',
      conduits: 'Conduits',
      copperCablings: 'Copper Cablings',
      fiberOpticCablings: 'Fiber Optic',
      customComponents: 'Custom'
    };
    return formattedTypes[type] || type;
  });
  
  const data = [];
  topFloors.forEach((floor, y) => {
    componentTypes.forEach((type, x) => {
      data.push([x, y, floor.counts[type]]);
    });
  });
  
  const chartOptions = {
    tooltip: {
      position: 'top',
      formatter: function (params) {
        return `${yAxisData[params.value[1]]}<br>${xAxisData[params.value[0]]}: ${params.value[2]}`;
      }
    },
    grid: {
      height: '70%',
      top: '10%'
    },
    xAxis: {
      type: 'category',
      data: xAxisData,
      axisLabel: {
        interval: 0,
        rotate: 45
      },
      splitArea: {
        show: true
      }
    },
    yAxis: {
      type: 'category',
      data: yAxisData,
      splitArea: {
        show: true
      }
    },
    visualMap: {
      min: 0,
      max: 10,
      calculable: true,
      orient: 'horizontal',
      left: 'center',
      bottom: '0%'
    },
    series: [{
      name: 'Component Count',
      type: 'heatmap',
      data: data,
      label: {
        show: true
      },
      emphasis: {
        itemStyle: {
          shadowBlur: 10,
          shadowColor: 'rgba(0, 0, 0, 0.5)'
        }
      }
    }]
  };
  
  return createEChartInstance(elementId, chartOptions);
}