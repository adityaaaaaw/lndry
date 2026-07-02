import { VendorsController } from './vendors.controller.js'
import { VendorsService } from './vendors.service.js'
import { VendorsRepository } from './vendors.repository.js'

export default async function vendorRoutes(fastify) {
  const repository = new VendorsRepository()
  const service = new VendorsService(repository)
  const controller = new VendorsController(service)

  // Public/Onboarding routes (COMMENTED OUT - USE canonical /vendor-applications instead)
  // fastify.post('/apply', {
  //   preHandler: [fastify.authenticate],
  //   schema: {
  //     tags: ['Vendors'],
  //     summary: 'Apply for a new vendor onboarding application',
  //     body: {
  //       type: 'object',
  //       required: ['name', 'address_line1', 'city', 'state', 'pincode', 'lat', 'lng'],
  //       properties: {
  //         name: { type: 'string', minLength: 2, maxLength: 200 },
  //         description: { type: 'string' },
  //         logo_url: { type: 'string' },
  //         banner_url: { type: 'string' },
  //         phone: { type: 'string' },
  //         email: { type: 'string', format: 'email' },
  //         address_line1: { type: 'string' },
  //         address_line2: { type: 'string' },
  //         city: { type: 'string' },
  //         state: { type: 'string' },
  //         pincode: { type: 'string' },
  //         lat: { type: 'number' },
  //         lng: { type: 'number' },
  //         delivery_radius_km: { type: 'number', minimum: 0.5 },
  //         gst_number: { type: 'string' },
  //         pan_number: { type: 'string' },
  //         operating_hours: { type: 'object' }
  //       }
  //     }
  //   }
  // }, controller.apply.bind(controller))

  // fastify.get('/me', {
  //   preHandler: [fastify.authenticate],
  //   schema: {
  //     tags: ['Vendors'],
  //     summary: 'Get current vendor profile'
  //   }
  // }, controller.getProfile.bind(controller))

  // fastify.put('/me', {
  //   preHandler: [fastify.authenticate],
  //   schema: {
  //     tags: ['Vendors'],
  //     summary: 'Update current vendor profile'
  //   }
  // }, controller.updateProfile.bind(controller))

  // fastify.post('/me/documents', {
  //   preHandler: [fastify.authenticate],
  //   schema: {
  //     tags: ['Vendors'],
  //     summary: 'Upload onboarding KYC document',
  //     body: {
  //       type: 'object',
  //       required: ['documentType', 'fileUrl'],
  //       properties: {
  //         documentType: { type: 'string', enum: ['owner_identity', 'shop_photo', 'registration_document', 'gst_certificate'] },
  //         fileUrl: { type: 'string' }
  //       }
  //     }
  //   }
  // }, controller.uploadDocument.bind(controller))

  // Admin approval/review routes
  const adminPreHandlers = [fastify.authenticate, fastify.authorize(['ADMIN'])]

  fastify.get('/admin/list', {
    preHandler: adminPreHandlers,
    schema: {
      tags: ['Admin Vendors'],
      summary: 'List vendor applications [Admin]',
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'integer', default: 1 },
          limit: { type: 'integer', default: 20 },
          city: { type: 'string' },
          status: { type: 'string' },
          search: { type: 'string' }
        }
      }
    }
  }, controller.adminList.bind(controller))

  fastify.get('/admin/:id', {
    preHandler: adminPreHandlers,
    schema: {
      tags: ['Admin Vendors'],
      summary: 'Get vendor application details [Admin]',
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string', format: 'uuid' }
        }
      }
    }
  }, controller.adminGetDetails.bind(controller))

  fastify.post('/admin/:id/review', {
    preHandler: adminPreHandlers,
    schema: {
      tags: ['Admin Vendors'],
      summary: 'Review vendor application [Admin]',
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string', format: 'uuid' }
        }
      },
      body: {
        type: 'object',
        required: ['status'],
        properties: {
          status: { type: 'string', enum: ['APPROVED', 'REJECTED', 'CORRECTION_REQUIRED', 'SUSPENDED'] },
          approvedRadius: { type: 'number' },
          documentReviews: {
            type: 'array',
            items: {
              type: 'object',
              required: ['documentId', 'status'],
              properties: {
                documentId: { type: 'string', format: 'uuid' },
                status: { type: 'string', enum: ['APPROVED', 'REJECTED'] },
                rejectionReason: { type: 'string' }
              }
            }
          }
        }
      }
    }
  }, controller.adminReview.bind(controller))

  fastify.get('/admin/documents/:documentId/preview', {
    preHandler: adminPreHandlers,
    schema: {
      tags: ['Admin Vendors'],
      summary: 'Get secure watermarked preview of KYC document [Admin]',
      params: {
        type: 'object',
        required: ['documentId'],
        properties: {
          documentId: { type: 'string', format: 'uuid' }
        }
      }
    }
  }, controller.previewKycDocument.bind(controller))
}
