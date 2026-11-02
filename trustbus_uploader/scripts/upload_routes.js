// upload_routes.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int, bool }                                             = require("./shared/parse_csv");

const COLLECTION = "routes";
const CSV_FILE   = "../data/routes.csv";
const REQUIRED   = ["routeId","from","to","distanceKm","duration","region","minPrice","maxPrice","active"];

const VALID_REGIONS = new Set(["South","North","East","West","Cross"]);

(async () => {
  console.log("\n🗺️  TrustBus — Upload Routes");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const errors  = [];
      const region   = str(row.region);
      const distance = int(row.distanceKm);
      const minPrice = int(row.minPrice);
      const maxPrice = int(row.maxPrice);
      if (!row.routeId)                errors.push("missing routeId");
      if (!VALID_REGIONS.has(region))  errors.push(`invalid region: "${region}"`);
      if (distance <= 0)               errors.push("distanceKm must be > 0");
      if (minPrice >= maxPrice)        errors.push("minPrice must be < maxPrice");
      if (str(row.from).toLowerCase() === str(row.to).toLowerCase())
        errors.push("from and to cannot be the same");
      if (errors.length) { skipped.push({ line: i + 2, id: row.routeId, errors }); return; }
      docs.push({
        routeId:    str(row.routeId),
        from:       str(row.from),
        to:         str(row.to),
        fromLower:  str(row.from).toLowerCase(),
        toLower:    str(row.to).toLowerCase(),
        distanceKm: distance,
        duration:   str(row.duration),
        region,
        minPrice,
        maxPrice,
        active:     bool(row.active, true),
        createdAt:  admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line} [${s.id}]: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} routes...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: region+active, from+to+active, distanceKm (ASC)");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();