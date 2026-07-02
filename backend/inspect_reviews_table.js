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
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'reviews'
    `);
    console.table(res.rows);
  } catch (e) {
    console.error(e.message);
  } finally {
    await pool.end();
  }
}
run();
