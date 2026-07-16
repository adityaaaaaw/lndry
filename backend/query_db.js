import pg from 'pg'
import dotenv from 'dotenv'

dotenv.config()

async function run() {
  const pool = new pg.Pool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  })

  try {
    console.log('--- USERS ---')
    const users = await pool.query('SELECT id, phone, role FROM users LIMIT 10')
    console.log(users.rows)

    console.log('--- VENDORS ---')
    const vendors = await pool.query('SELECT id, name, phone FROM vendors LIMIT 10')
    console.log(vendors.rows)

    console.log('--- VENDOR EMPLOYEES ---')
    const employees = await pool.query('SELECT id, user_id, vendor_id, role, permissions FROM vendor_employees LIMIT 10')
    console.log(employees.rows)
  } catch (err) {
    console.error(err)
  } finally {
    await pool.end()
  }
}

run()
