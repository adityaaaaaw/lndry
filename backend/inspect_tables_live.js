import { query, pool } from './src/config/database.js'

async function run() {
  try {
    console.log('=== Column Names in slot_holds ===')
    const colsSlotHolds = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'slot_holds'`
    )
    console.log(colsSlotHolds.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in vendor_services ===')
    const colsVendorServices = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'vendor_services'`
    )
    console.log(colsVendorServices.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in vendor_service_rates ===')
    const colsVendorServiceRates = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'vendor_service_rates'`
    )
    console.log(colsVendorServiceRates.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in order_lines ===')
    const colsOrderLines = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'order_lines'`
    )
    console.log(colsOrderLines.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in garment_types ===')
    const colsGarmentTypes = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'garment_types'`
    )
    console.log(colsGarmentTypes.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in reviews ===')
    const colsReviews = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'reviews'`
    )
    console.log(colsReviews.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in vendor_slots ===')
    const colsVendorSlots = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'vendor_slots'`
    )
    console.log(colsVendorSlots.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== Column Names in orders ===')
    const colsOrders = await pool.query(
      `SELECT column_name, data_type 
       FROM information_schema.columns 
       WHERE table_name = 'orders'`
    )
    console.log(colsOrders.rows.map(r => `${r.column_name}: ${r.data_type}`))

    console.log('\n=== All Tables in Database ===')
    const allTables = await pool.query(
      `SELECT table_name 
       FROM information_schema.tables 
       WHERE table_schema = 'public'`
    )
    console.log(allTables.rows.map(r => r.table_name))

    console.log('\n=== Testing pickup-slots query ===')
    const testQuery = await pool.query(
      `SELECT
         vs.id AS slot_id,
         (SELECT COUNT(*)::int FROM slot_holds WHERE slot_id = vs.id AND booking_date = $1 AND expires_at > NOW() AND status = 'ACTIVE') AS holds_count,
         (SELECT COUNT(*)::int FROM orders WHERE vendor_slot_id = vs.id AND pickup_date = $1 AND status NOT IN ('PAYMENT_FAILED', 'VENDOR_REJECTED', 'AUTO_REJECTED', 'CUSTOMER_CANCELLED', 'ADMIN_CANCELLED', 'REFUNDED')) AS orders_count
       FROM vendor_slots vs
       WHERE vs.id = ANY($2::uuid[])`,
      ['2026-07-20', ['11111111-1111-4111-9111-111111111111']]
    )
    console.log(testQuery.rows)

    console.log('\n=== All rows in vendor_slots ===')
    const allSlots = await pool.query(
      `SELECT * FROM vendor_slots`
    )
    console.log(allSlots.rows)

  } catch (err) {
    console.error(err)
  } finally {
    await pool.end()
  }
}

run()
