// shared/firebase.js — FINAL SECURE VERSION

const admin = require("firebase-admin");

let _db = null;

// ─────────────────────────────────────────
// 🔐 Initialize Firebase (ENV-based)
// ─────────────────────────────────────────
function initFirebase() {
  if (_db) return _db;

  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!keyPath) {
    throw new Error(
      "❌ GOOGLE_APPLICATION_CREDENTIALS not set.\n" +
      "👉 Run this:\n" +
      'setx GOOGLE_APPLICATION_CREDENTIALS "C:\\secure_keys\\your-key.json"'
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(require(keyPath)),
    });

    console.log("✅ Firebase Connected");
  }

  _db = admin.firestore();
  return _db;
}

// ─────────────────────────────────────────
// 🗑️ Clear Collection (batch delete)
// ─────────────────────────────────────────
async function clearCollection(db, collectionName, batchSize = 499) {
  const snap = await db.collection(collectionName).get();

  if (snap.empty) {
    console.log(`  ⚪ ${collectionName}: nothing to delete`);
    return 0;
  }

  let deleted = 0;

  for (let i = 0; i < snap.docs.length; i += batchSize) {
    const batch = db.batch();

    snap.docs.slice(i, i + batchSize).forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    deleted += Math.min(batchSize, snap.docs.length - i);
  }

  console.log(`  🗑️ Deleted ${deleted} docs from "${collectionName}"`);
  return deleted;
}

// ─────────────────────────────────────────
// 🚀 Upload Docs (chunk parallel)
// ─────────────────────────────────────────
async function uploadDocs(db, collectionName, docs, chunkSize = 20) {
  let uploaded = 0;
  let failed = 0;
  const failures = [];

  for (let i = 0; i < docs.length; i += chunkSize) {
    const chunk = docs.slice(i, i + chunkSize);

    const results = await Promise.allSettled(
      chunk.map(doc => db.collection(collectionName).add(doc))
    );

    results.forEach((res, idx) => {
      if (res.status === "fulfilled") {
        uploaded++;
      } else {
        failed++;
        failures.push({
          doc: chunk[idx],
          reason: res.reason?.message || "Unknown error",
        });
      }
    });

    process.stdout.write(
      `\r  ↑ ${uploaded + failed}/${docs.length} (${failed} failed)`
    );
  }

  console.log(); // new line

  return { uploaded, failed, failures };
}

// ─────────────────────────────────────────
// ⚙️ CLI Args
// ─────────────────────────────────────────
const args = {
  dryRun: process.argv.includes("--dry-run"),
  skipDelete: process.argv.includes("--skip-delete"),
  verbose: process.argv.includes("--verbose"),
};

// ─────────────────────────────────────────
// 📊 Print Result
// ─────────────────────────────────────────
function printResult(collection, stats) {
  console.log(`\n${"─".repeat(45)}`);
  console.log(`  Collection : ${collection}`);
  console.log(`  Uploaded   : ${stats.uploaded}`);
  console.log(`  Failed     : ${stats.failed}`);

  if (stats.failures.length) {
    stats.failures.forEach(f => {
      console.log(
        `  ✗ ${JSON.stringify(f.doc).slice(0, 80)} → ${f.reason}`
      );
    });
  }

  console.log(`${"─".repeat(45)}\n`);
}

// ─────────────────────────────────────────
// 📦 Export
// ─────────────────────────────────────────
module.exports = {
  initFirebase,
  clearCollection,
  uploadDocs,
  args,
  printResult,
  admin,
};