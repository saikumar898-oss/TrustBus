// upload_operators.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, float, bool }                                           = require("./shared/parse_csv");

const COLLECTION = "operators";
const CSV_FILE   = "../data/operators.csv";
const REQUIRED   = ["operatorId","name","fullName","hqCity","state","type","founded","phone","email","avgRating","active"];

const VALID_TYPES = new Set(["govt","private"]);

(async () => {
  console.log("\n🏢 TrustBus — Upload Operators");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const errors  = [];
      const type     = str(row.type);
      const rating   = float(row.avgRating);
      if (!row.operatorId)           errors.push("missing operatorId");
      if (!VALID_TYPES.has(type))    errors.push(`invalid type: "${type}"`);
      if (rating < 1 || rating > 5)  errors.push(`avgRating ${rating} must be 1–5`);
      if (!row.email?.includes("@")) errors.push("invalid email");
      if (errors.length) { skipped.push({ line: i + 2, id: row.operatorId, errors }); return; }
      docs.push({
        operatorId: str(row.operatorId),
        name:       str(row.name),
        fullName:   str(row.fullName),
        hqCity:     str(row.hqCity),
        state:      str(row.state),
        type,
        founded:    str(row.founded),
        phone:      str(row.phone),
        email:      str(row.email).toLowerCase(),
        avgRating:  rating,
        active:     bool(row.active, true),
        createdAt:  admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line}: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} operators...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: type+active, state+active, avgRating (DESC)");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();