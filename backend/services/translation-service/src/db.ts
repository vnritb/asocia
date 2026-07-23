import { Pool } from "pg";
import fs from "node:fs";
import path from "node:path";

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL ?? "postgres://asocia:asocia@localhost:5432/asocia"
});

export async function ensureSchema(): Promise<void> {
  const sql = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf-8");
  await pool.query(sql);
}
