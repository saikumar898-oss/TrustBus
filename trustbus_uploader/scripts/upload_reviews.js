// upload_reviews.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int, bool }                                             = require("./shared/parse_csv");

const COLLECTION = "reviews";
const CSV_FILE   = "../data/reviews.csv";
const REQUIRED   = ["reviewId","bookingId","userId","busName","from","to","rating","comment","reviewDate","helpful"];

(async () => {
  console.log("\n⭐ TrustBus — Upload Reviews");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const rating = int(row.rating);
      if (rating < 1 || rating > 5) {
        skipped.push({ line: i + 2, id: row.reviewId, errors: [`invalid rating: ${rating}`] });
        return;
      }
      docs.push({
        reviewId:   str(row.reviewId),
        bookingId:  str(row.bookingId),
        userId:     str(row.userId),
        busName:    str(row.busName),
        from:       str(row.from),
        to:         str(row.to),
        rating,
        comment:    str(row.comment),
        reviewDate: str(row.reviewDate),
        helpful:    bool(row.helpful),
        createdAt:  admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line}: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} reviews...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: busName+rating, userId+createdAt, from+to+rating");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();