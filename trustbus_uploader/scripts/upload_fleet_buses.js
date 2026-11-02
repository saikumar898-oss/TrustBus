// upload_fleet_buses.js
// Run:      node upload_fleet_buses.js
// Dry-run:  node upload_fleet_buses.js --dry-run
// Prereq:   npm install firebase-admin csv-parser

const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int }                                                   = require("./shared/parse_csv");

const COLLECTION = "fleet_buses";
const CSV_FILE   = "../data/fleet_buses.csv";

const REQUIRED = [
  "busId","busNumber","route","status","capacity","driverName",
  "operator","regDate","permitExpiry","licenseNo","city",
];

const VALID_STATUSES = new Set(["Active","Inactive","Maintenance"]);

function transform(row) {
  const errors  = [];
  const status   = str(row.status);
  const capacity = int(row.capacity);

  if (!row.busId)                  errors.push("missing busId");
  if (!row.busNumber)              errors.push("missing busNumber");
  if (!VALID_STATUSES.has(status)) errors.push(`invalid status: "${status}"`);
  if (capacity <= 0 || capacity > 80) errors.push(`capacity ${capacity} out of range (1–80)`);

  return {
    errors,
    doc: {
      busId:        str(row.busId),
      busNumber:    str(row.busNumber),
      route:        str(row.route),
      status,
      capacity,
      driverName:   str(row.driverName),
      operator:     str(row.operator),
      regDate:      str(row.regDate),
      permitExpiry: str(row.permitExpiry),
      licenseNo:    str(row.licenseNo),
      city:         str(row.city),
      createdAt:    admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

(async () => {
  console.log("\n🚌 TrustBus — Upload Fleet Buses");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);

  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows from ${CSV_FILE}`);

    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const { errors, doc } = transform(row);
      if (errors.length) skipped.push({ line: i + 2, id: row.busId, errors });
      else docs.push(doc);
    });

    if (skipped.length) {
      console.log(`  ⚠️  ${skipped.length} rows skipped:`);
      skipped.forEach(s => console.log(`    Line ${s.line} [${s.id}]: ${s.errors.join(", ")}`));
    }

    if (args.dryRun) {
      console.log(`\n  ✅ Dry run: ${docs.length} valid docs would be uploaded.\n`);
      return;
    }

    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);

    console.log(`  ↑ Uploading ${docs.length} fleet buses...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);

    console.log("  📌 Suggested indexes:");
    console.log("     fleet_buses: city (ASC), status (ASC)");
    console.log("     fleet_buses: operator (ASC), status (ASC)");

    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) {
    console.error("  ❌", err.message);
    process.exit(1);
  }
})();