import { collection, query, where, orderBy, getDocs, doc, getDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase/config.js';

/**
 * Get reports by status
 */
export async function getReportsByStatus(status) {
  try {
    console.log(`Getting reports with status: ${status}`);
    const reportsRef = collection(db, 'technical_visit_reports');
    let q;
    
    if (status === 'all') {
      q = query(reportsRef);
    } else {
      q = query(reportsRef, where('status', '==', status));
    }
    
    const querySnapshot = await getDocs(q);
    console.log(`Found ${querySnapshot.docs.length} reports`);
    
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error("Error getting reports:", error);
    throw error;
  }
}

/**
 * Get a single report by ID
 */
export async function getReportById(reportId) {
  try {
    console.log(`Getting report with ID: ${reportId}`);
    const docRef = doc(db, 'technical_visit_reports', reportId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      console.log('Report found');
      return {
        id: docSnap.id,
        ...docSnap.data()
      };
    } else {
      console.log('Report not found');
      throw new Error('Report not found');
    }
  } catch (error) {
    console.error("Error getting report:", error);
    throw error;
  }
}

/**
 * Update report status
 */
export async function updateReportStatus(reportId, newStatus) {
  try {
    console.log(`Updating report ${reportId} to status: ${newStatus}`);
    await updateDoc(doc(db, 'technical_visit_reports', reportId), {
      status: newStatus,
      lastModified: new Date().toISOString()
    });
    console.log('Report status updated successfully');
    return true;
  } catch (error) {
    console.error("Error updating report status:", error);
    throw error;
  }
}

/**
 * Delete report
 */
export async function deleteReport(reportId) {
  try {
    console.log(`Deleting report with ID: ${reportId}`);
    await deleteDoc(doc(db, 'technical_visit_reports', reportId));
    console.log('Report deleted successfully');
    return true;
  } catch (error) {
    console.error("Error deleting report:", error);
    throw error;
  }
}

/**
 * Get all users
 */
export async function getUsers() {
  try {
    console.log('Getting all users');
    const usersRef = collection(db, 'users');
    const querySnapshot = await getDocs(usersRef);
    console.log(`Found ${querySnapshot.docs.length} users`);
    
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error("Error getting users:", error);
    throw error;
  }
}

/**
 * Update user
 */
export async function updateUser(authUid, userData) {
  try {
    console.log(`Updating user with authUid: ${authUid}`);
    await updateDoc(doc(db, 'users', authUid), {
      name: userData.name,
      email: userData.email,
      role: userData.role,
      updatedAt: new Date().toISOString()
    });
    console.log('User updated successfully');
    return true;
  } catch (error) {
    console.error("Error updating user:", error);
    throw error;
  }
}

/**
 * Delete user
 */
export async function deleteUser(authUid) {
  try {
    console.log(`Deleting user with authUid: ${authUid}`);
    await deleteDoc(doc(db, 'users', authUid));
    console.log('User deleted successfully');
    return true;
  } catch (error) {
    console.error("Error deleting user:", error);
    throw error;
  }
}