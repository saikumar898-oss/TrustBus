// upload_safety_reports.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str }                                                        = require("./shared/parse_csv");

const COLLECTION = "safetyReports";
const CSV_FILE   = "../data/safety_reports.csv";
const REQUIRED   = ["reportId","busNumber","type","severity","title","description","location","status","reportDate","reportedBy"];

const VALID_TYPES      = new Set(["Accident","Breakdown","Fire","Medical","Inspection","Other"]);
const VALID_SEVERITIES = new Set(["Low","Medium","High","Critical"]);
const VALID_STATUSES   = new Set(["Open","In Progress","Resolved"]);

(async () => {
  console.log("\n🛡️  TrustBus — Upload Safety Reports");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const errors  = [];
      const type     = str(row.type);
      const severity = str(row.severity);
      const status   = str(row.status);
      if (!VALID_TYPES.has(type))       errors.push(`invalid type: "${type}"`);
      if (!VALID_SEVERITIES.has(severity)) errors.push(`invalid severity: "${severity}"`);
      if (!VALID_STATUSES.has(status))  errors.push(`invalid status: "${status}"`);
      if (!row.busNumber)               errors.push("missing busNumber");
      if (errors.length) { skipped.push({ line: i + 2, id: row.reportId, errors }); return; }
      docs.push({
        reportId:    str(row.reportId),
        busNumber:   str(row.busNumber),
        type,
        severity,
        title:       str(row.title),
        description: str(row.description),
        location:    str(row.location),
        reportStatus: status,
        reportDate:  str(row.reportDate),
        reportedBy:  str(row.reportedBy),
        createdAt:   admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line} [${s.id}]: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} safety reports...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: busNumber+reportStatus, severity+reportStatus, type+reportDate");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();