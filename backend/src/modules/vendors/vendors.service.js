import slugify from 'slugify'
import { getClient, query } from '../../config/database.js'
import { logger } from '../../config/logger.js'
import { WatermarkService } from '../watermark/watermark.service.js'
import { emit as emitAudit } from '../../utils/audit-log.js'


export class VendorsService {
  constructor(repository) {
    this.repo = repository
    this.watermarkService = new WatermarkService()
  }

  async apply(userId, data) {
    // Generate unique slug
    let baseSlug = slugify(data.name, { lower: true, strict: true })
    const slugCount = await this.repo.getSlugCount(baseSlug)
    const slug = slugCount > 0 ? `${baseSlug}-${slugCount + 1}` : baseSlug

    const branchCode = 'VND-' + Math.random().toString(36).substring(2, 8).toUpperCase()

    const applicationData = {
      ...data,
      slug,
      branch_code: branchCode,
      created_by: userId,
      status: 'WAITING_FOR_APPROVAL',
      is_active: false
    }

    const vendor = await this.repo.create(applicationData)
    logger.info({ vendorId: vendor.id, userId }, 'Vendor onboarding application submitted')
    return vendor
  }

  async getProfile(userId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) return null
    const documents = await this.repo.getDocuments(vendor.id)
    return {
      ...vendor,
      documents
    }
  }

  async updateProfile(userId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) {
      throw { statusCode: 404, message: 'Vendor profile not found' }
    }
    // Cannot update status directly
    delete data.status
    delete data.is_active
    delete data.created_by
    return this.repo.update(vendor.id, data)
  }

  async uploadDocument(userId, type, fileUrl) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) {
      throw { statusCode: 404, message: 'Vendor profile not found' }
    }
    return this.repo.addDocument(vendor.id, type, fileUrl)
  }

  async adminList(filters) {
    return this.repo.findMany(filters)
  }

  async adminGetDetails(id) {
    const app = await this.repo.findApplicationById(id)
    if (app) {
      const documents = await this.repo.getApplicationDocuments(id)
      return {
        ...app,
        documents
      }
    }
    const vendor = await this.repo.findById(id)
    if (!vendor) return null
    const documents = await this.repo.getDocuments(id)
    return {
      ...vendor,
      documents
    }
  }

  async adminReview(id, { status, approvedRadius, documentReviews }) {
    const app = await this.repo.findApplicationById(id)
    if (!app) {
      const vendor = await this.repo.findById(id)
      if (!vendor) {
        throw { statusCode: 404, message: 'Application or Vendor not found' }
      }
      const updates = { status }
      if (status === 'SUSPENDED') {
        updates.is_active = false
        updates.account_enabled = false
      } else if (status === 'APPROVED') {
        updates.is_active = true
        updates.vendor_approved = true
        updates.account_enabled = true
      }
      return this.repo.update(id, updates)
    }

    const validStatuses = ['APPROVED', 'REJECTED', 'CORRECTION_REQUIRED', 'SUSPENDED']
    if (!validStatuses.includes(status)) {
      throw { statusCode: 400, message: 'Invalid vendor status' }
    }

    const updates = { status }
    if (status === 'APPROVED') {
      updates.approved_service_radius_km = approvedRadius || app.requested_service_radius_km
    }

    if (Array.isArray(documentReviews)) {
      for (const dr of documentReviews) {
        await this.repo.updateDocumentStatus(dr.documentId, dr.status, dr.rejectionReason)
      }
    }

    const updatedApp = await this.repo.updateApplication(id, updates)

    if (status === 'APPROVED') {
      let baseSlug = slugify(app.name, { lower: true, strict: true })
      const slugCount = await this.repo.getSlugCount(baseSlug)
      const slug = slugCount > 0 ? `${baseSlug}-${slugCount + 1}` : baseSlug
      const branchCode = 'VND-' + Math.random().toString(36).substring(2, 8).toUpperCase()

      const vendor = await this.repo.create({
        name: app.name,
        slug,
        branch_code: branchCode,
        description: app.description,
        email: app.email,
        phone: app.phone,
        address_line1: app.address_line1,
        address_line2: app.address_line2,
        city: app.city,
        state: app.state,
        pincode: app.pincode,
        lat: app.lat,
        lng: app.lng,
        requested_service_radius_km: app.requested_service_radius_km,
        approved_service_radius_km: approvedRadius || app.requested_service_radius_km,
        bank_account_number: app.bank_account_number,
        bank_ifsc: app.bank_ifsc,
        bank_name: app.bank_name,
        bank_holder_name: app.bank_holder_name,
        gst_number: app.gst_number,
        pan_number: app.pan_number,
        created_by: app.owner_id,
        status: 'APPROVED',
        vendor_approved: true,
        account_enabled: true,
        marketplace_published: false
      })

      await query(
        `UPDATE vendor_documents SET vendor_id = $1 WHERE vendor_application_id = $2`,
        [vendor.id, app.id]
      )

      await query(
        `INSERT INTO vendor_employees (vendor_id, user_id, role, status)
         VALUES ($1, $2, 'VENDOR_OWNER', 'ACTIVE')
         ON CONFLICT (vendor_id, user_id) DO UPDATE SET role = 'VENDOR_OWNER', status = 'ACTIVE'`,
        [vendor.id, app.owner_id]
      )
    }

    logger.info({ vendorApplicationId: id, status, approvedRadius }, 'Vendor application reviewed by admin')
    return updatedApp
  }

  async previewKycDocument(docId, user) {
    const doc = await this.repo.getDocumentById(docId)
    if (!doc) {
      throw { statusCode: 404, message: 'Document not found' }
    }

    const isAdmin = user.role === 'ADMIN' || user.platform_role === 'ADMIN'
    if (!isAdmin) {
      const userVendor = await this.repo.findByUserId(user.id)
      if (!userVendor || userVendor.id !== doc.vendor_id) {
        throw { statusCode: 403, message: 'Forbidden' }
      }
    }

    const vendor = await this.repo.findById(doc.vendor_id)
    const settings = await this.repo.getWatermarkSettings() || { enabled: true, text: 'For LNDRY Verification Only', position: 'center', scale: 1.0, opacity: 0.4 }

    emitAudit('kyc_document_viewed', {
      actor_user_id: user.id,
      actor_role: user.role || user.platform_role || null,
      actor_shop_id: doc.vendor_id,
      target_type: 'vendor_document',
      target_id: docId,
      before: null,
      after: { document_type: doc.document_type },
    })

    return this.watermarkService.processKycPreview(
      doc.file_url,
      vendor ? vendor.branch_code : 'VND-UNKNOWN',
      settings
    )
  }

  async createApplication(userId, data) {
    const existing = await this.repo.findApplicationByOwnerId(userId)
    if (existing) {
      return existing
    }

    const applicationData = {
      owner_id: userId,
      name: data.name || 'My Laundry Business',
    }

    return this.repo.createApplication(applicationData)
  }

  async getApplicationMe(userId) {
    const app = await this.repo.findApplicationByOwnerId(userId)
    if (!app) {
      throw { statusCode: 404, message: 'No onboarding application found' }
    }
    const documents = await this.repo.getApplicationDocuments(app.id)
    
    const missingSteps = []
    if (!app.bank_account_number || !app.bank_ifsc) {
      missingSteps.push('bank_details')
    }
    if (!app.gst_number && !app.pan_number) {
      missingSteps.push('tax_details')
    }
    const requiredDocs = ['owner_identity', 'shop_photo']
    const uploadedDocs = documents.map(d => d.document_type)
    for (const docType of requiredDocs) {
      if (!uploadedDocs.includes(docType)) {
        missingSteps.push(`document:${docType}`)
      }
    }

    return {
      application: {
        ...app,
        documents
      },
      missing_steps: missingSteps,
    }
  }

  async verifyApplicationAccess(userId, applicationId) {
    const app = await this.repo.findApplicationById(applicationId)
    if (!app) {
      throw { statusCode: 404, message: 'Application not found' }
    }
    if (app.owner_id !== userId) {
      throw { statusCode: 403, message: 'Forbidden' }
    }
    return app
  }

  async updateApplicationOwner(userId, appId, data) {
    await this.verifyApplicationAccess(userId, appId)
    const updates = {}
    if (data.email) updates.email = data.email
    if (data.phone) updates.phone = data.phone
    if (data.bank_account_number) updates.bank_account_number = data.bank_account_number
    if (data.bank_ifsc) updates.bank_ifsc = data.bank_ifsc
    if (data.bank_name) updates.bank_name = data.bank_name
    if (data.bank_holder_name) updates.bank_holder_name = data.bank_holder_name
    
    return this.repo.updateApplication(appId, updates)
  }

  async updateApplicationBusiness(userId, appId, data) {
    await this.verifyApplicationAccess(userId, appId)
    const updates = {}
    if (data.name) updates.name = data.name
    if (data.description) updates.description = data.description
    if (data.operating_hours) updates.operating_hours = data.operating_hours
    if (data.gst_number) updates.gst_number = data.gst_number
    if (data.pan_number) updates.pan_number = data.pan_number

    return this.repo.updateApplication(appId, updates)
  }

  async updateApplicationLocation(userId, appId, data) {
    await this.verifyApplicationAccess(userId, appId)
    const updates = {}
    if (data.address_line1) updates.address_line1 = data.address_line1
    if (data.address_line2) updates.address_line2 = data.address_line2
    if (data.city) updates.city = data.city
    if (data.state) updates.state = data.state
    if (data.pincode) updates.pincode = data.pincode
    if (data.lat !== undefined) updates.lat = data.lat
    if (data.lng !== undefined) updates.lng = data.lng

    return this.repo.updateApplication(appId, updates)
  }

  async updateApplicationRadius(userId, appId, data) {
    await this.verifyApplicationAccess(userId, appId)
    const updates = {}
    if (data.requested_radius_km !== undefined) {
      updates.requested_service_radius_km = data.requested_radius_km
    }
    return this.repo.updateApplication(appId, updates)
  }

  async addApplicationDocument(userId, appId, type, fileUrl) {
    await this.verifyApplicationAccess(userId, appId)
    return this.repo.addApplicationDocument(appId, type, fileUrl)
  }

  async deleteApplicationDocument(userId, appId, docId) {
    await this.verifyApplicationAccess(userId, appId)
    const doc = await this.repo.getDocumentById(docId)
    if (!doc || doc.vendor_application_id !== appId) {
      throw { statusCode: 404, message: 'Document not found' }
    }
    await query('DELETE FROM vendor_documents WHERE id = $1', [docId])
    return { success: true }
  }

  async submitApplication(userId, appId) {
    const app = await this.verifyApplicationAccess(userId, appId)
    if (app.status !== 'DRAFT' && app.status !== 'CORRECTION_REQUIRED') {
      throw { statusCode: 400, message: 'Application is already submitted' }
    }
    const docs = await this.repo.getApplicationDocuments(appId)
    const uploadedTypes = docs.map(d => d.document_type)
    if (!uploadedTypes.includes('owner_identity') || !uploadedTypes.includes('shop_photo')) {
      throw { statusCode: 400, message: 'Missing required onboarding documents: Owner Identity and Shop Photo are required' }
    }
    return this.repo.updateApplication(appId, { status: 'WAITING_FOR_APPROVAL' })
  }

  async resubmitApplication(userId, appId) {
    const app = await this.verifyApplicationAccess(userId, appId)
    if (app.status !== 'CORRECTION_REQUIRED') {
      throw { statusCode: 400, message: 'Application is not in CORRECTION_REQUIRED status' }
    }
    const docs = await this.repo.getApplicationDocuments(appId)
    const uploadedTypes = docs.map(d => d.document_type)
    if (!uploadedTypes.includes('owner_identity') || !uploadedTypes.includes('shop_photo')) {
      throw { statusCode: 400, message: 'Missing required onboarding documents: Owner Identity and Shop Photo are required' }
    }
    return this.repo.updateApplication(appId, { status: 'WAITING_FOR_APPROVAL' })
  }

  async publishProfile(userId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) {
      throw { statusCode: 404, message: 'Vendor profile not found' }
    }
    if (vendor.status !== 'APPROVED') {
      throw { statusCode: 400, message: 'Cannot publish vendor profile until application is APPROVED' }
    }
    const hasService = await this.repo.hasActiveService(vendor.id)
    if (!hasService) {
      throw { statusCode: 400, message: 'Cannot publish vendor without at least one active service' }
    }

    return this.repo.update(vendor.id, { is_active: true })
  }

  async getPublicPreview(userId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) {
      throw { statusCode: 404, message: 'Vendor profile not found' }
    }
    const documents = await this.repo.getDocuments(vendor.id)
    return {
      ...vendor,
      documents
    }
  }

  async updateProfileLocation(userId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) {
      throw { statusCode: 404, message: 'Vendor profile not found' }
    }
    const updates = {
      address_line1: data.address_line1,
      address_line2: data.address_line2,
      city: data.city,
      state: data.state,
      pincode: data.pincode,
      lat: data.lat,
      lng: data.lng,
      status: 'WAITING_FOR_APPROVAL',
      is_active: false
    }
    return this.repo.update(vendor.id, updates)
  }

  async getVendorCategories() {
    const { rows } = await query('SELECT id, name, slug, description, image, display_order FROM categories WHERE is_active = true ORDER BY display_order ASC')
    return rows
  }

  async getVendorServices(userId, { status, categoryId, page = 1, limit = 20 } = {}) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const conditions = ['vs.vendor_id = $1', 'vs.deleted_at IS NULL']
    const params = [vendor.id]
    let idx = 2

    if (categoryId) {
      conditions.push(`gr.category_id = $${idx++}`)
      params.push(categoryId)
    }

    if (status !== undefined) {
      conditions.push(`vs.is_available = $${idx++}`)
      params.push(status === 'active' || status === 'true')
    }

    const offset = (page - 1) * limit
    const where = conditions.join(' AND ')

    const { rows } = await query(
      `SELECT vs.id, vs.name, vs.description, vs.inclusions, vs.exclusions,
              vs.completion_time_hours, vs.image_asset_id, vs.status, vs.is_available,
              vs.category_id, sc.name AS category_name
       FROM vendor_services vs
       LEFT JOIN service_categories sc ON vs.category_id = sc.id
       WHERE ${where}
       ORDER BY sc.name, vs.name
       LIMIT $${idx} OFFSET $${idx + 1}`,
      [...params, limit, offset]
    )

    const countRes = await query(
      `SELECT COUNT(*)::int as total
       FROM vendor_services vs
       WHERE ${where}`,
      params
    )

    return {
      services: rows,
      total: countRes.rows[0].total,
      page,
      limit
    }
  }

  async createVendorServiceDraft(userId, categoryId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const catRes = await query('SELECT name, description FROM service_categories WHERE id = $1', [categoryId])
    const cat = catRes.rows[0]
    if (!cat) throw { statusCode: 404, message: 'Service category not found' }

    const { rows: vsRows } = await query(
      `INSERT INTO vendor_services (vendor_id, category_id, name, description, status, is_available)
       VALUES ($1, $2, $3, $4, 'DRAFT', false)
       ON CONFLICT (vendor_id, category_id) DO UPDATE SET deleted_at = NULL, status = 'DRAFT'
       RETURNING id, status`,
      [vendor.id, categoryId, cat.name, cat.description]
    )
    const vs = vsRows[0]

    const { rows: gts } = await query('SELECT id FROM garment_types WHERE category_id = $1 AND is_active = true', [categoryId])
    for (const gt of gts) {
      await query(
        `INSERT INTO vendor_service_rates (vendor_service_id, garment_type_id, rate_paise, is_active)
         VALUES ($1, $2, 0, true)
         ON CONFLICT (vendor_service_id, garment_type_id) DO UPDATE SET is_active = true`,
        [vs.id, gt.id]
      )
    }

    return { id: vs.id, status: vs.status, category_id: categoryId, name: cat.name }
  }

  async getVendorServiceDetails(userId, serviceId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const serviceRes = await query(
      `SELECT vs.id, vs.name, vs.description, vs.inclusions, vs.exclusions, 
              vs.completion_time_hours, vs.image_asset_id, vs.status, vs.is_available, vs.category_id,
              sc.name AS category_name
       FROM vendor_services vs
       LEFT JOIN service_categories sc ON vs.category_id = sc.id
       WHERE vs.id = $1 AND vs.vendor_id = $2 AND vs.deleted_at IS NULL`,
      [serviceId, vendor.id]
    )

    const service = serviceRes.rows[0]
    if (!service) throw { statusCode: 404, message: 'Vendor service not found' }

    const { rows: rates } = await query(
      `SELECT vsr.id AS rate_id, vsr.rate_paise, vsr.is_active,
              gt.id AS garment_type_id, gt.name AS garment_name, gt.unit
       FROM vendor_service_rates vsr
       JOIN garment_types gt ON vsr.garment_type_id = gt.id
       WHERE vsr.vendor_service_id = $1 AND gt.is_active = true`,
      [serviceId]
    )

    return {
      category: { name: service.category_name, id: service.category_id },
      service,
      garments: rates.map(r => ({
        garment_rate_id: r.garment_type_id,
        garment_name: r.garment_name,
        unit: r.unit,
        rate_paise: r.rate_paise,
        is_available: r.is_active,
        vendor_service_id: serviceId
      }))
    }
  }

  async updateVendorService(userId, serviceId, isAvailable) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    await query(
      `UPDATE vendor_services
       SET is_available = $1, updated_at = NOW()
       WHERE id = $2 AND vendor_id = $3`,
      [isAvailable, serviceId, vendor.id]
    )

    return { success: true }
  }

  async deleteVendorService(userId, serviceId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    await query(
      `UPDATE vendor_services
       SET deleted_at = NOW(), updated_at = NOW()
       WHERE id = $1 AND vendor_id = $2`,
      [serviceId, vendor.id]
    )

    return { success: true }
  }

  async addGarmentRate(userId, serviceId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const vsRes = await query('SELECT category_id FROM vendor_services WHERE id = $1 AND vendor_id = $2', [serviceId, vendor.id])
    const vs = vsRes.rows[0]
    if (!vs) throw { statusCode: 404, message: 'Vendor service not found' }

    let gtId = data.garment_type_id
    if (!gtId && data.garment_type_name) {
      const slug = slugify(data.garment_type_name, { lower: true, strict: true }) + '-' + Math.random().toString(36).substring(2, 6)
      const gtRes = await query(
        `INSERT INTO garment_types (name, slug, unit, category_id, is_active)
         VALUES ($1, $2, $3, $4, true)
         ON CONFLICT (slug) DO UPDATE SET is_active = true
         RETURNING id`,
        [data.garment_type_name, slug, data.rate_unit || 'piece', vs.category_id]
      )
      gtId = gtRes.rows[0].id
    }

    if (!gtId) throw { statusCode: 400, message: 'garment_type_id or garment_type_name is required' }

    const ratePaise = parseInt(data.rate_paise, 10) || 0
    await query(
      `INSERT INTO vendor_service_rates (vendor_service_id, garment_type_id, rate_paise, is_active)
       VALUES ($1, $2, $3, true)
       ON CONFLICT (vendor_service_id, garment_type_id)
       DO UPDATE SET rate_paise = $3, is_active = true`,
      [serviceId, gtId, ratePaise]
    )

    return { garment_type_id: gtId, rate_paise: ratePaise, is_available: true }
  }

  async updateGarmentRate(userId, serviceId, garmentTypeId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const updates = []
    const params = []
    let idx = 1

    if (data.rate_paise !== undefined) {
      updates.push(`rate_paise = $${idx++}`)
      params.push(parseInt(data.rate_paise, 10) || 0)
    }

    if (data.is_available !== undefined) {
      updates.push(`is_active = $${idx++}`)
      params.push(data.is_available === true)
    }

    if (updates.length === 0) return { success: true }

    params.push(serviceId, garmentTypeId)
    await query(
      `UPDATE vendor_service_rates
       SET ${updates.join(', ')}, updated_at = NOW()
       WHERE vendor_service_id = $${idx} AND garment_type_id = $${idx + 1}`,
      params
    )

    return { success: true }
  }

  async deleteGarmentRate(userId, serviceId, garmentTypeId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    await query(
      `UPDATE vendor_service_rates
       SET is_active = false, updated_at = NOW()
       WHERE vendor_service_id = $1 AND garment_type_id = $2`,
      [serviceId, garmentTypeId]
    )

    return { success: true }
  }

  async bulkUpsertGarmentRates(userId, serviceId, items) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    for (const item of items) {
      const ratePaise = parseInt(item.rate_paise, 10) || 0
      const garmentTypeId = item.garment_type_id || item.garment_rate_id
      await query(
        `INSERT INTO vendor_service_rates (vendor_service_id, garment_type_id, rate_paise, is_active)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (vendor_service_id, garment_type_id)
         DO UPDATE SET rate_paise = $3, is_active = $4, updated_at = NOW()`,
        [serviceId, garmentTypeId, ratePaise, item.is_available !== false]
      )
    }

    return { success: true }
  }

  async publishService(userId, serviceId) {
    return this.updateVendorService(userId, serviceId, true)
  }

  async unpublishService(userId, serviceId, reason) {
    return this.updateVendorService(userId, serviceId, false)
  }

  async getCapacity(userId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const { rows: slots } = await query('SELECT id, day_of_week, start_time, end_time, max_orders, is_active FROM vendor_slots WHERE vendor_id = $1', [vendor.id])
    const { rows: exceptions } = await query('SELECT id, date, type, limit_count, reason FROM slot_exceptions WHERE vendor_id = $1', [vendor.id])

    return {
      daily_limit: vendor.operating_hours?.max_orders_per_day || null,
      weekly_availability: slots,
      exceptions
    }
  }

  async updateDailyLimit(userId, maxOrdersPerDay) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const operatingHours = vendor.operating_hours || {}
    operatingHours.max_orders_per_day = maxOrdersPerDay

    return this.repo.update(vendor.id, { operating_hours: operatingHours })
  }

  async getPickupSlots(userId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const { rows } = await query(
      'SELECT id, day_of_week, start_time, end_time, max_orders, is_active FROM vendor_slots WHERE vendor_id = $1',
      [vendor.id]
    )
    return rows
  }

  async createPickupSlot(userId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const { rows } = await query(
      `INSERT INTO vendor_slots (vendor_id, day_of_week, start_time, end_time, max_orders, is_active)
       VALUES ($1, $2, $3, $4, $5, true)
       RETURNING id, day_of_week, start_time, end_time, max_orders, is_active`,
      [vendor.id, data.day_of_week, data.start, data.end, data.max_orders || 5]
    )
    return rows[0]
  }

  async updatePickupSlot(userId, slotId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const updates = []
    const params = []
    let idx = 1

    if (data.max_orders !== undefined) {
      updates.push(`max_orders = $${idx++}`)
      params.push(data.max_orders)
    }

    if (data.is_active !== undefined) {
      updates.push(`is_active = $${idx++}`)
      params.push(data.is_active)
    }

    if (updates.length === 0) return { success: true }

    params.push(vendor.id, slotId)
    const { rows } = await query(
      `UPDATE vendor_slots
       SET ${updates.join(', ')}, updated_at = NOW()
       WHERE vendor_id = $${idx} AND id = $${idx + 1}
       RETURNING id, day_of_week, start_time, end_time, max_orders, is_active`,
      params
    )
    return rows[0] || null
  }

  async deletePickupSlot(userId, slotId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    await query('DELETE FROM vendor_slots WHERE vendor_id = $1 AND id = $2', [vendor.id, slotId])
    return { success: true }
  }

  async createCapacityException(userId, data) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    const { rows } = await query(
      `INSERT INTO slot_exceptions (vendor_id, date, type, limit_count, reason)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (vendor_id, date)
       DO UPDATE SET type = $3, limit_count = $4, reason = $5, created_at = NOW()
       RETURNING id, date, type, limit_count, reason`,
      [vendor.id, data.date, data.type, data.limit || null, data.reason || null]
    )
    return rows[0]
  }

  async deleteCapacityException(userId, exceptionId) {
    const vendor = await this.repo.findByUserId(userId)
    if (!vendor) throw { statusCode: 404, message: 'Vendor profile not found' }

    await query('DELETE FROM slot_exceptions WHERE vendor_id = $1 AND id = $2', [vendor.id, exceptionId])
    return { success: true }
  }
}


