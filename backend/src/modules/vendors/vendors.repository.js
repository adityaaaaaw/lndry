import { query } from '../../config/database.js'
import { logger } from '../../config/logger.js'

export class VendorsRepository {
  async create(data) {
    const { rows } = await query(
      `INSERT INTO vendors (
        name, slug, branch_code, description, logo_url, banner_url,
        phone, email, address_line1, address_line2, city, state, pincode,
        lat, lng, serviceable_pincodes, delivery_radius_km,
        operating_hours, commission_rate,
        bank_account_number, bank_ifsc, bank_name, bank_holder_name,
        gst_number, pan_number, created_by, status,
        vendor_approved, account_enabled, marketplace_published,
        requested_service_radius_km, approved_service_radius_km
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8, $9, $10, $11, $12, $13,
        $14, $15, $16, $17,
        $18, $19,
        $20, $21, $22, $23,
        $24, $25, $26, $27,
        $28, $29, $30,
        $31, $32
      )
      RETURNING id, name, slug, branch_code, description, logo_url, banner_url,
        phone, email, address_line1, address_line2, city, state, pincode,
        lat, lng, serviceable_pincodes, delivery_radius_km,
        is_active, operating_hours, commission_rate, status,
        bank_account_number, bank_ifsc, bank_name, bank_holder_name,
        gst_number, pan_number, created_by, created_at, updated_at,
        vendor_approved, account_enabled, marketplace_published,
        requested_service_radius_km, approved_service_radius_km`,
      [
        data.name, data.slug, data.branch_code,
        data.description || null, data.logo_url || null, data.banner_url || null,
        data.phone || null, data.email || null,
        data.address_line1, data.address_line2 || null,
        data.city, data.state, data.pincode,
        data.lat, data.lng,
        data.serviceable_pincodes || [],
        data.delivery_radius_km || 5.00,
        JSON.stringify(data.operating_hours || {}),
        data.commission_rate || 10.00,
        data.bank_account_number || null, data.bank_ifsc || null,
        data.bank_name || null, data.bank_holder_name || null,
        data.gst_number || null, data.pan_number || null,
        data.created_by, data.status || 'DRAFT',
        data.vendor_approved || false, data.account_enabled !== false, data.marketplace_published || false,
        data.requested_service_radius_km || 5.00, data.approved_service_radius_km || 5.00
      ]
    )
    return rows[0]
  }

  async findById(id) {
    const { rows } = await query(
      `SELECT id, name, slug, branch_code, description, logo_url, banner_url,
        phone, email, address_line1, address_line2, city, state, pincode,
        lat, lng, serviceable_pincodes, delivery_radius_km,
        is_active, operating_hours, commission_rate, status,
        bank_account_number, bank_ifsc, bank_name, bank_holder_name,
        gst_number, pan_number, created_by, created_at, updated_at,
        vendor_approved, account_enabled, marketplace_published,
        requested_service_radius_km, approved_service_radius_km
      FROM vendors
      WHERE id = $1 AND deleted_at IS NULL`,
      [id]
    )
    return rows[0] || null
  }

  async findByUserId(userId) {
    const { rows } = await query(
      `SELECT id, name, slug, branch_code, description, logo_url, banner_url,
        phone, email, address_line1, address_line2, city, state, pincode,
        lat, lng, serviceable_pincodes, delivery_radius_km,
        is_active, operating_hours, commission_rate, status,
        bank_account_number, bank_ifsc, bank_name, bank_holder_name,
        gst_number, pan_number, created_by, created_at, updated_at,
        vendor_approved, account_enabled, marketplace_published,
        requested_service_radius_km, approved_service_radius_km
      FROM vendors
      WHERE created_by = $1 AND deleted_at IS NULL
      LIMIT 1`,
      [userId]
    )
    return rows[0] || null
  }

  async update(id, data) {
    const fieldMap = {
      name: 'name',
      description: 'description',
      logo_url: 'logo_url',
      banner_url: 'banner_url',
      phone: 'phone',
      email: 'email',
      address_line1: 'address_line1',
      address_line2: 'address_line2',
      city: 'city',
      state: 'state',
      pincode: 'pincode',
      lat: 'lat',
      lng: 'lng',
      delivery_radius_km: 'delivery_radius_km',
      is_active: 'is_active',
      status: 'status',
      commission_rate: 'commission_rate',
      bank_account_number: 'bank_account_number',
      bank_ifsc: 'bank_ifsc',
      bank_name: 'bank_name',
      bank_holder_name: 'bank_holder_name',
      gst_number: 'gst_number',
      pan_number: 'pan_number',
      slug: 'slug',
      vendor_approved: 'vendor_approved',
      account_enabled: 'account_enabled',
      marketplace_published: 'marketplace_published',
      requested_service_radius_km: 'requested_service_radius_km',
      approved_service_radius_km: 'approved_service_radius_km'
    }

    const fields = []
    const params = []
    let idx = 1

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = $${idx++}`)
        params.push(data[key])
      }
    }

    if (data.operating_hours !== undefined) {
      fields.push(`operating_hours = $${idx++}`)
      params.push(JSON.stringify(data.operating_hours))
    }

    if (fields.length === 0) return this.findById(id)

    fields.push('updated_at = NOW()')
    params.push(id)

    const { rows } = await query(
      `UPDATE vendors SET ${fields.join(', ')}
       WHERE id = $${idx} AND deleted_at IS NULL
       RETURNING id, name, slug, branch_code, description, logo_url, banner_url,
        phone, email, address_line1, address_line2, city, state, pincode,
        lat, lng, serviceable_pincodes, delivery_radius_km,
        is_active, operating_hours, commission_rate, status,
        bank_account_number, bank_ifsc, bank_name, bank_holder_name,
        gst_number, pan_number, created_by, created_at, updated_at,
        vendor_approved, account_enabled, marketplace_published,
        requested_service_radius_km, approved_service_radius_km`,
      params
    )
    return rows[0] || null
  }

  async addDocument(vendorId, type, fileUrl) {
    const { rows } = await query(
      `INSERT INTO vendor_documents (vendor_id, document_type, file_url)
       VALUES ($1, $2, $3)
       RETURNING id, vendor_id, document_type, file_url, status, rejection_reason, created_at`,
      [vendorId, type, fileUrl]
    )
    return rows[0]
  }

  async getDocuments(vendorId) {
    const { rows } = await query(
      `SELECT id, vendor_id, document_type, file_url, status, rejection_reason, created_at
       FROM vendor_documents
       WHERE vendor_id = $1
       ORDER BY created_at DESC`,
      [vendorId]
    )
    return rows
  }

  async updateDocumentStatus(docId, status, reason = null) {
    const { rows } = await query(
      `UPDATE vendor_documents
       SET status = $1, rejection_reason = $2, updated_at = NOW()
       WHERE id = $3
       RETURNING id, vendor_id, document_type, file_url, status, rejection_reason`,
      [status, reason, docId]
    )
    return rows[0] || null
  }

  async findMany({ page = 1, limit = 20, city, status, search } = {}) {
    const offset = (page - 1) * limit
    const conditions = ['deleted_at IS NULL']
    const params = []
    let paramIdx = 1

    if (city) {
      conditions.push(`city ILIKE $${paramIdx++}`)
      params.push(`%${city}%`)
    }

    if (status) {
      conditions.push(`status = $${paramIdx++}`)
      params.push(status)
    }

    if (search) {
      conditions.push(`(name ILIKE $${paramIdx} OR slug ILIKE $${paramIdx} OR branch_code ILIKE $${paramIdx})`)
      params.push(`%${search}%`)
      paramIdx++
    }

    const where = conditions.join(' AND ')

    const [dataResult, countResult] = await Promise.all([
      query(
        `SELECT id, name, slug, branch_code, description, logo_url, banner_url,
          phone, email, address_line1, address_line2, city, state, pincode,
          lat, lng, delivery_radius_km, is_active, status, created_at
        FROM vendors
        WHERE ${where}
        ORDER BY created_at DESC
        LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`,
        [...params, limit, offset]
      ),
      query(
        `SELECT COUNT(*)::int AS total FROM vendors WHERE ${where}`,
        params
      )
    ])

    return {
      vendors: dataResult.rows,
      total: countResult.rows[0]?.total || 0
    }
  }

  async getSlugCount(baseSlug) {
    const { rows } = await query(
      `SELECT COUNT(*)::int AS count FROM vendors WHERE slug LIKE $1`,
      [`${baseSlug}%`]
    )
    return rows[0]?.count || 0
  }

  async getDocumentById(docId) {
    const { rows } = await query(
      `SELECT id, vendor_id, document_type, file_url, status, rejection_reason, created_at
       FROM vendor_documents
       WHERE id = $1`,
      [docId]
    )
    return rows[0] || null
  }

  async getWatermarkSettings() {
    const { rows } = await query(
      `SELECT enabled, text, logo_url, position, scale, opacity
       FROM watermark_settings
       LIMIT 1`
    )
    return rows[0] || null
  }

  async hasActiveService(vendorId) {
    const { rows } = await query(
      'SELECT 1 FROM vendor_services WHERE vendor_id = $1 AND is_active = true LIMIT 1',
      [vendorId]
    )
    return rows.length > 0
  }

  // ─── Vendor Applications repository methods ───────────
  async findApplicationById(id) {
    const { rows } = await query(
      `SELECT * FROM vendor_applications WHERE id = $1`,
      [id]
    )
    return rows[0] || null
  }

  async findApplicationByOwnerId(ownerId) {
    const { rows } = await query(
      `SELECT * FROM vendor_applications WHERE owner_id = $1 LIMIT 1`,
      [ownerId]
    )
    return rows[0] || null
  }

  async createApplication(data) {
    const { rows } = await query(
      `INSERT INTO vendor_applications (
        owner_id, name, status, requested_service_radius_km, approved_service_radius_km
      ) VALUES (
        $1, $2, 'DRAFT', 5.00, 5.00
      )
      RETURNING *`,
      [data.owner_id, data.name]
    )
    return rows[0]
  }

  async updateApplication(id, data) {
    const fieldMap = {
      name: 'name',
      email: 'email',
      phone: 'phone',
      bank_account_number: 'bank_account_number',
      bank_ifsc: 'bank_ifsc',
      bank_name: 'bank_name',
      bank_holder_name: 'bank_holder_name',
      description: 'description',
      gst_number: 'gst_number',
      pan_number: 'pan_number',
      address_line1: 'address_line1',
      address_line2: 'address_line2',
      city: 'city',
      state: 'state',
      pincode: 'pincode',
      lat: 'lat',
      lng: 'lng',
      requested_service_radius_km: 'requested_service_radius_km',
      approved_service_radius_km: 'approved_service_radius_km',
      status: 'status',
      rejection_reason: 'rejection_reason'
    }

    const fields = []
    const params = []
    let idx = 1

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = $${idx++}`)
        params.push(data[key])
      }
    }

    if (data.operating_hours !== undefined) {
      fields.push(`operating_hours = $${idx++}`)
      params.push(JSON.stringify(data.operating_hours))
    }

    if (fields.length === 0) return this.findApplicationById(id)

    fields.push('updated_at = NOW()')
    params.push(id)

    const { rows } = await query(
      `UPDATE vendor_applications SET ${fields.join(', ')}
       WHERE id = $${idx}
       RETURNING *`,
      params
    )
    return rows[0] || null
  }

  async addApplicationDocument(appId, type, fileUrl) {
    const { rows } = await query(
      `INSERT INTO vendor_documents (vendor_application_id, document_type, file_url)
       VALUES ($1, $2, $3)
       RETURNING id, vendor_application_id, document_type, file_url, status, rejection_reason, created_at`,
      [appId, type, fileUrl]
    )
    return rows[0]
  }

  async getApplicationDocuments(appId) {
    const { rows } = await query(
      `SELECT id, vendor_application_id, document_type, file_url, status, rejection_reason, created_at
       FROM vendor_documents
       WHERE vendor_application_id = $1
       ORDER BY created_at DESC`,
      [appId]
    )
    return rows
  }
}

