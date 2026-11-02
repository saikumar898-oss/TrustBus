// upload_payments.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, float }                                                 = require("./shared/parse_csv");

const COLLECTION = "payments";
const CSV_FILE   = "../data/payments.csv";
const REQUIRED   = ["paymentId","bookingId","userId","transactionId","method","gateway",
                    "baseAmount","tax","totalAmount","status","paymentDate"];

const VALID_METHODS   = new Set(["UPI","Credit Card","Debit Card","Net Banking","Wallet"]);
const VALID_STATUSES  = new Set(["success","failed","refunded","pending"]);
const VALID_GATEWAYS  = new Set(["Razorpay","Paytm","PhonePe","Google Pay","HDFC PG"]);

(async () => {
  console.log("\n💳 TrustBus — Upload Payments");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const errors  = [];
      const method  = str(row.method);
      const status  = str(row.status);
      const gateway = str(row.gateway);
      const total   = float(row.totalAmount);
      if (!VALID_METHODS.has(method))   errors.push(`invalid method: "${method}"`);
      if (!VALID_STATUSES.has(status))  errors.push(`invalid status: "${status}"`);
      if (!VALID_GATEWAYS.has(gateway)) errors.push(`invalid gateway: "${gateway}"`);
      if (total <= 0)                   errors.push("totalAmount must be > 0");
      if (!row.transactionId)           errors.push("missing transactionId");
      if (errors.length) { skipped.push({ line: i + 2, id: row.paymentId, errors }); return; }
      docs.push({
        paymentId:     str(row.paymentId),
        bookingId:     str(row.bookingId),
        userId:        str(row.userId),
        transactionId: str(row.transactionId),
        method,
        gateway,
        baseAmount:    float(row.baseAmount),
        tax:           float(row.tax),
        totalAmount:   total,
        status,
        paymentDate:   str(row.paymentDate),
        createdAt:     admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line}: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} payments...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: userId+status, method+status, gateway+paymentDate");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();