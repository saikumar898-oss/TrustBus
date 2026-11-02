// upload_all.js  —  runs every upload script in the correct order
// Run:       node upload_all.js
// Dry-run:   node upload_all.js --dry-run
// Skip a:    node upload_all.js --skip=bookings,payments
// Only run:  node upload_all.js --only=users,drivers

const { execSync } = require("child_process");
const path         = require("path");

// ── Parse --skip and --only flags ──
function getFlag(flag) {
  const arg = process.argv.find(a => a.startsWith(`--${flag}=`));
  return arg ? arg.replace(`--${flag}=`, "").split(",").map(s => s.trim()) : null;
}

const skipList = getFlag("skip") || [];
const onlyList = getFlag("only") || null;
const dryRun   = process.argv.includes("--dry-run") ? "--dry-run" : "";

// ── Upload order (dependencies respected) ──
// operators & routes have no deps → upload first
// drivers, fleet_buses reference operators
// bookings reference users & route_schedules
// payments & reviews reference bookings
// notifications reference users
const UPLOAD_ORDER = [
  { key: "operators",        script: "upload_operators.js",       desc: "Bus operators (22)" },
  { key: "routes",           script: "upload_routes.js",          desc: "Master routes (36)" },
  { key: "users",            script: "upload_users.js",           desc: "Users (30)" },
  { key: "drivers",          script: "upload_drivers.js",         desc: "Drivers (30)" },
  { key: "fleet_buses",      script: "upload_fleet_buses.js",     desc: "Fleet buses (30)" },
  { key: "route_schedules",  script: "upload_route_schedules.js", desc: "Route schedules (700)" },
  { key: "bookings",         script: "upload_bookings.js",        desc: "Bookings (200)" },
  { key: "reviews",          script: "upload_reviews.js",         desc: "Reviews (80)" },
  { key: "safety_reports",   script: "upload_safety_reports.js",  desc: "Safety reports (100)" },
  { key: "payments",         script: "upload_payments.js",        desc: "Payments (200)" },
  { key: "notifications",    script: "upload_notifications.js",   desc: "Notifications (150)" },
];

// ── Run ──
console.log("\n🚀 TrustBus — Upload All Collections");
console.log(`   Mode    : ${dryRun ? "DRY RUN" : "LIVE WRITE"}`);
if (skipList.length) console.log(`   Skipping: ${skipList.join(", ")}`);
if (onlyList)        console.log(`   Only    : ${onlyList.join(", ")}`);
console.log();

const results = [];
const start   = Date.now();

for (const { key, script, desc } of UPLOAD_ORDER) {
  // Filter by --only / --skip
  if (onlyList && !onlyList.includes(key)) continue;
  if (skipList.includes(key)) {
    console.log(`  ⏭️  Skipping ${key}`);
    results.push({ key, status: "skipped" });
    continue;
  }

  console.log(`\n${"═".repeat(50)}`);
  console.log(`  Running: ${script}  (${desc})`);
  console.log(`${"═".repeat(50)}`);

  const scriptPath = path.join(__dirname, script);
  const t0         = Date.now();

  try {
    execSync(`node "${scriptPath}" ${dryRun}`, { stdio: "inherit" });
    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    results.push({ key, status: "✅ success", elapsed });
  } catch (err) {
    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    results.push({ key, status: "❌ FAILED", elapsed });
    console.error(`\n  ❌ ${script} failed (exit code ${err.status})`);

    // Ask whether to continue
    if (!process.argv.includes("--continue-on-error")) {
      console.error("  Stopping. Re-run with --continue-on-error to skip failures.");
      break;
    }
  }
}

// ── Final Summary ──
const totalElapsed = ((Date.now() - start) / 1000).toFixed(1);
console.log(`\n${"═".repeat(50)}`);
console.log("  FINAL SUMMARY");
console.log(`${"═".repeat(50)}`);
results.forEach(r => {
  const time = r.elapsed ? `(${r.elapsed}s)` : "";
  console.log(`  ${r.status.padEnd(12)} ${r.key} ${time}`);
});
console.log(`${"─".repeat(50)}`);
console.log(`  Total time: ${totalElapsed}s`);
console.log(`${"═".repeat(50)}\n`);

const failed = results.filter(r => r.status.includes("FAILED")).length;
process.exit(failed > 0 ? 1 : 0);