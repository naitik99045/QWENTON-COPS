import * as admin from "firebase-admin";

let isConfigured = false;

if (!admin.apps.length) {
  try {
    const projectId = process.env.FIREBASE_PROJECT_ID || "qwenton-reelmarket";
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n")
      : undefined;

    if (clientEmail && privateKey) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        databaseURL:
          process.env.FIREBASE_DATABASE_URL ||
          "https://qwenton-reelmarket-default-rtdb.firebaseio.com",
        storageBucket:
          process.env.FIREBASE_STORAGE_BUCKET ||
          "qwenton-reelmarket.firebasestorage.app",
      });
      isConfigured = true;
      console.log("[FirebaseAdmin] Initialized with Service Account");
    } else {
      // Unauthenticated init for build-time static generation
      admin.initializeApp({
        projectId,
      });
      console.log("[FirebaseAdmin] Initialized in local/build mode (awaiting credentials)");
    }
  } catch (error) {
    console.warn("[FirebaseAdmin] Initialization warning:", error);
  }
}

export const hasFirebaseCredentials = isConfigured;
export const adminDb = isConfigured ? admin.firestore() : null;
export const adminAuth = isConfigured ? admin.auth() : null;
export default admin;
