// upload_bookings.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, int, float }                                            = require("./shared/parse_csv");

const COLLECTION = "bookings";
const CSV_FILE   = "../data/bookings.csv";
const REQUIRED   = ["bookingId","pnr","userId","busName","from","to","travelDate",
                    "bookingDate","departureTime","arrivalTime","busType",
                    "pricePerSeat","seatsBooked","seatNumbers","totalAmount","status"];

const VALID_STATUSES  = new Set(["confirmed","completed","cancelled","pending"]);
const VALID_BUS_TYPES = new Set(["AC Sleeper","Non AC Sleeper","AC Seater","Non AC Seater","Sleeper"]);

function transform(row) {
  const errors = [];
  const status  = str(row.status);
  const busType = str(row.busType);
  if (!VALID_STATUSES.has(status))   errors.push(`invalid status: "${status}"`);
  if (!VALID_BUS_TYPES.has(busType)) errors.push(`invalid busType: "${busType}"`);
  if (!row.pnr)  errors.push("missing pnr");
  if (!row.userId) errors.push("missing userId");

  return {
    errors,
    doc: {
      bookingId:     str(row.bookingId),
      pnr:           str(row.pnr),
      userId:        str(row.userId),
      busName:       str(row.busName),
      from:          str(row.from),
      to:            str(row.to),
      travelDate:    str(row.travelDate),
      bookingDate:   str(row.bookingDate),
      departureTime: str(row.departureTime),
      arrivalTime:   str(row.arrivalTime),
      busType,
      pricePerSeat:  int(row.pricePerSeat),
      seatsBooked:   int(row.seatsBooked),
      seatNumbers:   str(row.seatNumbers).split(",").map(s => s.trim()),
      totalAmount:   int(row.totalAmount),
      status,
      createdAt:     admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

(async () => {
  console.log("\n🎟️  TrustBus — Upload Bookings");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const { errors, doc } = transform(row);
      if (errors.length) skipped.push({ line: i + 2, id: row.bookingId, errors });
      else docs.push(doc);
    });
    if (skipped.length) {
      console.log(`  ⚠️  ${skipped.length} skipped:`);
      skipped.forEach(s => console.log(`    Line ${s.line}: ${s.errors.join(", ")}`));
    }
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} bookings...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: userId+status, from+to+travelDate, status+travelDate");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();