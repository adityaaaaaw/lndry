import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'lndry_user',
  password: 'lndry_password_dev',
  database: 'lndry_db'
});

async function run() {
  try {
    const res = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    console.log('\n--- TABLES ---');
    console.log(res.rows.map(r => r.table_name));
  } catch(e) {
    console.error("DB Error:", e.message);
  } finally {
    await pool.end();
  }
}
run();
