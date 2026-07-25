import { createPool } from "mariadb";
import fs from "node:fs";
import path from "node:path";

function getConfig() {
  const url = process.env.DATABASE_URL ?? "mariadb://asocia:asocia@localhost:3306/chat";
  const parsed = new URL(url);
  return {
    host: parsed.hostname,
    port: Number(parsed.port || 3306),
    user: decodeURIComponent(parsed.username || "asocia"),
    password: decodeURIComponent(parsed.password || ""),
    database: parsed.pathname.replace(/^\/+/, "") || "chat",
    connectionLimit: 10,
    multipleStatements: true
  };
}

const mariaPool = createPool(getConfig());

function translateSql(sql: string): string {
  let translated = sql.trim();
  translated = translated.replace(/\$(\d+)/g, "?");
  translated = translated.replace(/\bRETURNING\b.*$/gi, "");
  translated = translated.replace(/\bILIKE\b/gi, "LIKE");
  translated = translated.replace(/([\w.]+)\s+ASC\s+NULLS\s+LAST/gi, "$1 IS NULL, $1 ASC");
  translated = translated.replace(/\s+NULLS LAST\b/gi, "");
  translated = translated.replace(/ON CONFLICT\s*\(([^)]+)\)\s+DO UPDATE SET\s+(.+)$/i, "ON DUPLICATE KEY UPDATE $2");
  translated = translated.replace(/EXCLUDED\.(\w+)/gi, "VALUES($1)");
  translated = translated.replace(/\bON CONFLICT\s*(?:\([^)]*\))?\s*DO NOTHING\b/gi, "");
  if (/^INSERT\b/i.test(translated) && /ON CONFLICT\s*(?:\([^)]*\))?\s*DO NOTHING/i.test(sql)) {
    translated = translated.replace(/^INSERT\s+INTO\b/i, "INSERT IGNORE INTO");
  }
  return translated;
}

function normalizeResult(result: any) {
  if (Array.isArray(result)) {
    return { rows: result, rowCount: result.length };
  }

  if (result && typeof result === "object") {
    if (Array.isArray(result.rows)) {
      return { rows: result.rows, rowCount: result.rows.length, insertId: result.insertId, affectedRows: result.affectedRows };
    }
  }

  return { rows: [], rowCount: 0, insertId: result?.insertId, affectedRows: result?.affectedRows };
}

export const pool = {
  async query(sql: string, params?: unknown[]) {
    const result = await mariaPool.query(translateSql(sql), params ?? []);
    return normalizeResult(result);
  },
  async connect() {
    const connection = await mariaPool.getConnection();
    return {
      async query(sql: string, params?: unknown[]) {
        const result = await connection.query(translateSql(sql), params ?? []);
        return normalizeResult(result);
      },
      async beginTransaction() {
        await connection.beginTransaction();
      },
      async commit() {
        await connection.commit();
      },
      async rollback() {
        await connection.rollback();
      },
      release() {
        connection.release();
      }
    };
  },
  async end() {
    await mariaPool.end();
  }
};

export async function ensureSchema(): Promise<void> {
  const sql = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf-8");
  await pool.query(sql);
}
