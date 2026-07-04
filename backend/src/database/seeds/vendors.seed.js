import { v4 as uuidv4 } from 'uuid'

export async function seedVendors(pool) {
  console.log('🌱 Seeding vendors...')

  const vendorId = '11111111-1111-4111-8111-111111111111'

  // Insert Vendor
  await pool.query(
    `INSERT INTO vendors (
      id, name, slug, branch_code, description, phone, email,
      address_line1, city, state, pincode, lat, lng,
      delivery_radius_km, is_active, is_verified,
      vendor_approved, account_enabled, marketplace_published,
      approved_service_radius_km, status
    ) VALUES (
      $1, 'LNDRY Prime - Bengaluru Hub', 'lndry-prime-bengaluru', 'BLR-001', 'Premium garment care and eco-friendly dry cleaning.', '9876543200', 'prime@lndry.app',
      '100 Feet Road, Indiranagar', 'Bengaluru', 'Karnataka', '560038', 12.9716, 77.5946,
      25.0, true, true,
      true, true, true,
      25.0, 'APPROVED'
    ) ON CONFLICT (id) DO UPDATE SET
      vendor_approved = true,
      account_enabled = true,
      marketplace_published = true,
      approved_service_radius_km = 25.0,
      status = 'APPROVED',
      deleted_at = NULL`,
    [vendorId]
  )

  // Fetch all garment_types
  const gtRes = await pool.query(`SELECT id, name, category_id FROM garment_types WHERE is_active = true`)
  
  let servicesCount = 0
  for (const gt of gtRes.rows) {
    const serviceId = uuidv4()
    await pool.query(
      `INSERT INTO vendor_services (id, vendor_id, category_id, garment_rate_id, name, status)
       VALUES ($1, $2, $3, $4, $5, 'PUBLISHED')`,
      [serviceId, vendorId, gt.category_id, gt.id, gt.name]
    )

    await pool.query(
      `INSERT INTO vendor_service_rates (id, vendor_service_id, garment_type_id, rate_paise, is_active)
       VALUES ($1, $2, $3, 4900, true)`,
      [uuidv4(), serviceId, gt.id]
    )
    servicesCount++
  }

  // Insert pickup slots for days 0 to 6
  await pool.query(`DELETE FROM vendor_slots WHERE vendor_id = $1`, [vendorId])
  let slotsCount = 0
  for (let day = 0; day <= 6; day++) {
    await pool.query(
      `INSERT INTO vendor_slots (id, vendor_id, day_of_week, start_time, end_time, max_orders, is_active)
       VALUES ($1, $2, $3, '08:00:00', '12:00:00', 50, true)`,
      [uuidv4(), vendorId, day]
    )
    await pool.query(
      `INSERT INTO vendor_slots (id, vendor_id, day_of_week, start_time, end_time, max_orders, is_active)
       VALUES ($1, $2, $3, '14:00:00', '18:00:00', 50, true)`,
      [uuidv4(), vendorId, day]
    )
    slotsCount += 2
  }

  console.log(`  ✅ 1 vendor seeded with ${servicesCount} services and ${slotsCount} slots`)
}
