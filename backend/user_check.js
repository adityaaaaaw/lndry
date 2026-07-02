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
      SELECT id, email, role, platform_role, is_active FROM users WHERE email='admin@lndry.com'
    `);
        console.table(res.rows);
    } catch (e) {
        console.error(e.message);
    } finally { pool.end(); }
}
run();
