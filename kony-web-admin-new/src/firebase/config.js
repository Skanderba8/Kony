import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { getStorage } from 'firebase/storage';

// Firebase configuration - use your Flutter app's Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyA_i_snqrJHccBp2qpMLhFfhyRVwBoJ7z0",
  authDomain: "kony-25092.firebaseapp.com",
  projectId: "kony-25092",
  storageBucket: "kony-25092.firebasestorage.app",
  messagingSenderId: "373594331946",
  appId: "1:373594331946:web:20c17dfa80cdba1bcd9c53",
  measurementId: "G-QE6LX3NEDT"
};

// Initialize Firebase services
console.log('Initializing Firebase...');
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);
const storage = getStorage(app);
console.log('Firebase initialized');

export { app, db, auth, storage };