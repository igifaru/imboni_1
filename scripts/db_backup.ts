/**
 * Database Backup Script
 * Run with: npx ts-node -r tsconfig-paths/register scripts/db_backup.ts
 */
import { exec } from 'child_process';
import path from 'path';
import fs from 'fs';

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupDir = path.join(process.cwd(), 'backups');
const filename = `imboni-backup-${timestamp}.sql`;

if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

const dbUrl = process.env.DATABASE_URL ?? '';
const match = dbUrl.match(/postgresql:\/\/(\w+):([^@]+)@([^/]+)\/(\w+)/);

if (!match) {
  console.error('Could not parse DATABASE_URL');
  process.exit(1);
}

const [, user, password, host, dbname] = match;
const cmd = `pg_dump -U ${user} -h ${host} ${dbname} > ${path.join(backupDir, filename)}`;

console.log(`Starting backup: ${filename}`);
exec(cmd, { env: { ...process.env, PGPASSWORD: password } }, (err) => {
  if (err) { console.error('Backup failed:', err.message); process.exit(1); }
  console.log(`Backup complete: backups/${filename}`);
});
