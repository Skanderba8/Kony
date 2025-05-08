// src/firebase/config.js
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { getStorage } from 'firebase/storage';
import { getPerformance } from 'firebase/performance';
import { environment } from '../environments/environment.js';

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
const app = initializeApp(environment.firebase);
const db = getFirestore(app);
const auth = getAuth(app);
const storage = getStorage(app);
const performance = getPerformance(app);
console.log('Firebase initialized');

export { app, db, auth, storage, performance };

