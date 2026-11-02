// upload_route_schedules.js  (your original buses_full.csv)
// Run:      node upload_route_schedules.js
// Dry-run:  node upload_route_schedules.js --dry-run
// Prereq:   npm install firebase-admin csv-parser

const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int, float }                                            = require("./shared/parse_csv");

const COLLECTION = "buses";          // keep same name as your existing app
const CSV_FILE   = "../data/buses_full.csv";

const REQUIRED = [
  "busName","from","to","departureTime","arrivalTime","price","seats","busType","rating","days",
];

const VALID_BUS_TYPES = new Set([
  "AC Sleeper","Non AC Sleeper","AC Seater","Non AC Seater","Sleeper",
]);
const VALID_DAYS = new Set(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]);

const AMENITY_MAP = {
  "AC Sleeper":     ["wifi","charging","water"],
  "AC Seater":      ["charging","water"],
  "Sleeper":        ["water"],
  "Non AC Sleeper": [],
  "Non AC Seater":  [],
};

function transform(row) {
  const errors  = [];
  const busType = str(row.busType);
  const price   = int(row.price);
  const seats   = int(row.seats);
  const rating  = float(row.rating);

  if (!row.busName)                  errors.push("missing busName");
  if (!row.from)                     errors.push("missing from");
  if (!row.to)                       errors.push("missing to");
  if (!VALID_BUS_TYPES.has(busType)) errors.push(`invalid busType: "${busType}"`);
  if (price <= 0 || price > 10000)   errors.push(`price ${price} out of range`);
  if (seats <= 0 || seats > 60)      errors.push(`seats ${seats} out of range`);
  if (rating < 1 || rating > 5)      errors.push(`rating ${rating} must be 1–5`);
  if (str(row.from).toLowerCase() === str(row.to).toLowerCase())
    errors.push("from and to cannot be the same city");

  const rawDays = str(row.days);
  const days    = rawDays
    ? rawDays.split("|").map(d => d.trim()).filter(d => VALID_DAYS.has(d))
    : ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];

  return {
    errors,
    doc: {
      busName:       str(row.busName),
      from:          str(row.from),
      to:            str(row.to),
      fromLower:     str(row.from).toLowerCase(),
      toLower:       str(row.to).toLowerCase(),
      departureTime: str(row.departureTime),
      arrivalTime:   str(row.arrivalTime),
      price,
      seats,
      busType,
      rating,
      days,
      amenities:     AMENITY_MAP[busType] || [],
      createdAt:     admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

(async () => {
  console.log("\n🗓️  TrustBus — Upload Route Schedules (buses_full.csv)");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);

  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows from ${CSV_FILE}`);

    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const { errors, doc } = transform(row);
      if (errors.length) skipped.push({ line: i + 2, id: `${row.busName} ${row.from}→${row.to}`, errors });
      else docs.push(doc);
    });

    if (skipped.length) {
      console.log(`  ⚠️  ${skipped.length} rows skipped:`);
      skipped.forEach(s => console.log(`    Line ${s.line} [${s.id}]: ${s.errors.join(", ")}`));
    }

    if (args.dryRun) {
      // Route summary
      const routeMap = {};
      docs.forEach(d => {
        const key = `${d.from} → ${d.to}`;
        routeMap[key] = (routeMap[key] || 0) + 1;
      });
      console.log(`\n  ✅ Dry run: ${docs.length} valid docs, ${Object.keys(routeMap).length} routes.\n`);
      return;
    }

    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);

    console.log(`  ↑ Uploading ${docs.length} route schedules...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);

    console.log("  📌 Required Firestore composite indexes:");
    console.log("     buses: from (ASC), to (ASC), days (Array contains)");
    console.log("     buses: from (ASC), to (ASC), price (ASC)");
    console.log("     buses: from (ASC), to (ASC), rating (DESC)");
    console.log("     buses: from (ASC), to (ASC), busType (ASC)");

    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) {
    console.error("  ❌", err.message);
    process.exit(1);
  }
})();