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
    console.log('🌱 Inserting test users...')

    // 1. Luxe/Prime Vendor ID
    const vendorId = '198fb742-901b-4bd7-8b54-0b67cbce35b4'

    // 2. Insert Customer User (8888888888)
    const customerUserId = 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1'
    await pool.query(
      `INSERT INTO users (id, phone, role) 
       VALUES ($1, $2, 'CUSTOMER') 
       ON CONFLICT (phone) DO UPDATE SET role = 'CUSTOMER'
       RETURNING id, phone, role`,
      [customerUserId, '8888888888']
    )
    console.log('  ✅ Seeded Customer User with phone 8888888888')

    // 3. Insert Vendor Owner User (7777777777)
    const vendorOwnerUserId = 'd1d1d1d1-d1d1-4d1d-8d1d-d1d1d1d1d1d1'
    await pool.query(
      `INSERT INTO users (id, phone, role) 
       VALUES ($1, $2, 'CUSTOMER') 
       ON CONFLICT (phone) DO UPDATE SET role = 'CUSTOMER'
       RETURNING id, phone, role`,
      [vendorOwnerUserId, '7777777777']
    )
    console.log('  ✅ Seeded Vendor Owner User with phone 7777777777')

    // 4. Link 7777777777 to Vendor as VENDOR_OWNER
    const employeeId = 'e1e1e1e1-e1e1-4e1e-8e1e-e1e1e1e1e1e1'
    const permissions = [
      'shop_orders.view',
      'shop_orders.update_status',
      'shop_orders.assign_rider',
      'shop_orders.cancel',
      'vendor_services.create',
      'vendor_services.update',
      'vendor_services.delete',
      'vendor_services.view',
      'vendor_staff.create',
      'vendor_staff.update',
      'vendor_staff.delete',
      'vendor_staff.view'
    ]
    await pool.query(
      `INSERT INTO vendor_employees (id, user_id, vendor_id, role, permissions, is_active)
       VALUES ($1, $2, $3, 'VENDOR_OWNER', $4, true)
       ON CONFLICT (id) DO UPDATE SET 
         user_id = $2,
         vendor_id = $3,
         role = 'VENDOR_OWNER',
         permissions = $4,
         is_active = true,
         deleted_at = NULL`,
      [employeeId, vendorOwnerUserId, vendorId, JSON.stringify(permissions)]
    )
    console.log('  ✅ Linked 7777777777 as VENDOR_OWNER of vendor 11111111-1111-4111-8111-111111111111')

  } catch (err) {
    console.error('Seed failed:', err)
  } finally {
    await pool.end()
  }
}

run()
