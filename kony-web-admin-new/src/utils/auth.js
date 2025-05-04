import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc, collection, query, where, getDocs } from 'firebase/firestore';
import { auth, db } from '../firebase/config.js';

/**
 * Signs in with email and password
 */
export async function signIn(email, password) {
  try {
    console.log(`Attempting to sign in with email: ${email}`);
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    console.log('Sign-in successful');
    return userCredential.user;
  } catch (error) {
    console.error("Error signing in:", error);
    throw error;
  }
}

/**
 * Signs out the current user
 */
export async function logOut() {
  try {
    console.log('Logging out...');
    await signOut(auth);
    console.log('Logged out successfully');
    return true;
  } catch (error) {
    console.error("Error signing out:", error);
    throw error;
  }
}

/**
 * Gets the current user's role from Firestore
 */
export async function getUserRole(userId) {
  try {
    console.log(`Getting role for user ID: ${userId}`);
    
    // Try direct document lookup first
    const userDoc = await getDoc(doc(db, 'users', userId));
    
    if (userDoc.exists()) {
      console.log('User document found with direct lookup');
      return userDoc.data().role;
    }
    
    console.log('User document not found with direct lookup, trying authUid field...');
    
    // Fall back to querying by authUid field
    const q = query(collection(db, 'users'), where('authUid', '==', userId));
    const querySnapshot = await getDocs(q);
    
    if (!querySnapshot.empty) {
      console.log('User document found with authUid query');
      return querySnapshot.docs[0].data().role;
    }
    
    console.log('No user document found');
    return null;
  } catch (error) {
    console.error("Error getting user role:", error);
    return null;
  }
}