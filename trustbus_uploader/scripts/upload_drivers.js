// upload_drivers.js
// Run:      node upload_drivers.js
// Dry-run:  node upload_drivers.js --dry-run
// Prereq:   npm install firebase-admin csv-parser

const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int, float }                                            = require("./shared/parse_csv");

const COLLECTION = "drivers";
const CSV_FILE   = "../data/drivers.csv";

const REQUIRED = [
  "driverId","name","licenseNo","phone","assignedBus","status",
  "experience","rating","bloodGroup","joiningDate","city","operator",
];

const VALID_STATUSES  = new Set(["On Duty","Off Duty","On Leave"]);
const VALID_BLOOD     = new Set(["A+","A-","B+","B-","AB+","AB-","O+","O-"]);

function transform(row) {
  const errors = [];

  const status     = str(row.status);
  const bloodGroup = str(row.bloodGroup);
  const experience = int(row.experience);
  const rating     = float(row.rating);

  if (!row.driverId)              errors.push("missing driverId");
  if (!row.name)                  errors.push("missing name");
  if (!row.licenseNo)             errors.push("missing licenseNo");
  if (!VALID_STATUSES.has(status))errors.push(`invalid status: "${status}"`);
  if (!VALID_BLOOD.has(bloodGroup)) errors.push(`invalid bloodGroup: "${bloodGroup}"`);
  if (experience < 0 || experience > 50) errors.push(`experience ${experience} out of range`);
  if (rating < 1 || rating > 5)   errors.push(`rating ${rating} must be 1–5`);

  return {
    errors,
    doc: {
      driverId:    str(row.driverId),
      name:        str(row.name),
      licenseNo:   str(row.licenseNo),
      phone:       str(row.phone),
      assignedBus: str(row.assignedBus),
      status,
      experience,
      rating,
      bloodGroup,
      joiningDate: str(row.joiningDate),
      city:        str(row.city),
      operator:    str(row.operator),
      createdAt:   admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

(async () => {
  console.log("\n🧑‍✈️  TrustBus — Upload Drivers");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);

  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows from ${CSV_FILE}`);

    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const { errors, doc } = transform(row);
      if (errors.length) skipped.push({ line: i + 2, id: row.driverId, errors });
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

    console.log(`  ↑ Uploading ${docs.length} drivers...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);

    console.log("  📌 Suggested indexes:");
    console.log("     drivers: status (ASC), operator (ASC)");
    console.log("     drivers: city (ASC), status (ASC)");
    console.log("     drivers: rating (DESC)");

    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) {
    console.error("  ❌", err.message);
    process.exit(1);
  }
})();