    // upload_notifications.js
const { initFirebase, clearCollection, uploadDocs, args, printResult, admin } = require("./shared/firebase");
const { parseCsv, str, bool }                                                  = require("./shared/parse_csv");

const COLLECTION = "notifications";
const CSV_FILE   = "../data/notifications.csv";
const REQUIRED   = ["notifId","userId","type","title","body","channel","read","createdAt"];

const VALID_TYPES    = new Set(["booking_confirmed","booking_cancelled","bus_delayed","bus_on_time",
                                "offer","payment_success","payment_failed","review_request","system"]);
const VALID_CHANNELS = new Set(["push","email","sms"]);

(async () => {
  console.log("\n🔔 TrustBus — Upload Notifications");
  console.log(`   Mode: ${args.dryRun ? "DRY RUN" : "LIVE"}\n`);
  try {
    const { rows } = await parseCsv(CSV_FILE, REQUIRED);
    console.log(`  📋 Parsed ${rows.length} rows`);
    const docs = [], skipped = [];
    rows.forEach((row, i) => {
      const errors  = [];
      const type    = str(row.type);
      const channel = str(row.channel);
      if (!VALID_TYPES.has(type))      errors.push(`invalid type: "${type}"`);
      if (!VALID_CHANNELS.has(channel))errors.push(`invalid channel: "${channel}"`);
      if (!row.userId)                 errors.push("missing userId");
      if (!row.title)                  errors.push("missing title");
      if (errors.length) { skipped.push({ line: i + 2, id: row.notifId, errors }); return; }
      docs.push({
        notifId:   str(row.notifId),
        userId:    str(row.userId),
        type,
        title:     str(row.title),
        body:      str(row.body),
        channel,
        read:      bool(row.read, false),
        createdAt: str(row.createdAt),
        uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (skipped.length) skipped.forEach(s => console.log(`  ⚠️  Line ${s.line}: ${s.errors.join(", ")}`));
    if (args.dryRun) { console.log(`\n  ✅ Dry run: ${docs.length} valid.\n`); return; }
    const db = initFirebase();
    if (!args.skipDelete) await clearCollection(db, COLLECTION);
    console.log(`  ↑ Uploading ${docs.length} notifications...`);
    const stats = await uploadDocs(db, COLLECTION, docs);
    printResult(COLLECTION, stats);
    console.log("  📌 Indexes: userId+read, userId+type, channel+createdAt");
    process.exit(stats.failed > 0 ? 1 : 0);
  } catch (err) { console.error("  ❌", err.message); process.exit(1); }
})();