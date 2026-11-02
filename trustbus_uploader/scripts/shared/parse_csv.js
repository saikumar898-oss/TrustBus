// shared/parse_csv.js — FINAL PRO VERSION

const csv = require("csv-parser");
const fs  = require("fs");

/**
 * Parse a CSV file into structured rows
 * @param {string} filePath
 * @param {string[]} required
 * @returns {Promise<{ rows: object[], warnings: object[] }>}
 */
async function parseCsv(filePath, required = []) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`❌ CSV not found: ${filePath}`);
  }

  const rows = [];
  const warnings = [];

  await new Promise((resolve, reject) => {
    fs.createReadStream(filePath)
      .pipe(csv({
        mapHeaders: ({ header }) => header.trim(), // ✅ clean headers
        skipLines: 0,
      }))
      .on("headers", headers => {
        if (required.length) {
          const missing = required.filter(c => !headers.includes(c));
          if (missing.length) {
            return reject(new Error(
              `❌ Missing columns: ${missing.join(", ")}\n` +
              `👉 Found: ${headers.join(", ")}`
            ));
          }
        }
      })
      .on("data", row => {
        // ❗ Skip completely empty rows
        const isEmpty = Object.values(row).every(v => !v || v.trim() === "");
        if (!isEmpty) rows.push(row);
      })
      .on("end", resolve)
      .on("error", reject);
  });

  return { rows, warnings };
}

// ─────────────────────────────────────────
// 🔢 Helpers
// ─────────────────────────────────────────

function int(val, fallback = 0) {
  const n = parseInt(val, 10);
  return isNaN(n) ? fallback : n;
}

function float(val, fallback = 0) {
  const n = parseFloat(val);
  return isNaN(n) ? fallback : n;
}

function bool(val, fallback = false) {
  if (val === undefined || val === null || val === "") return fallback;

  const v = val.toString().trim().toLowerCase();

  if (["true", "1", "yes"].includes(v)) return true;
  if (["false", "0", "no"].includes(v)) return false;

  return fallback;
}

function str(val) {
  return (val ?? "").toString().trim();
}

module.exports = {
  parseCsv,
  int,
  float,
  bool,
  str,
};