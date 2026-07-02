import { VendorOrdersController } from './vendor-orders.controller.js'
import { VendorOrdersService } from './vendor-orders.service.js'

/**
 * Vendor Orders routes plugin
 * Prefix: /api/v1/vendor-orders
 *
 * All routes require authentication. The service layer resolves vendor ownership
 * from the authenticated user (vendor owner or employee).
 *
 * Endpoints:
 *   GET    /                             — List vendor orders (with status filter)
 *   GET    /stats                        — Vendor dashboard stats
 *   GET    /:orderId                     — Get order detail
 *   POST   /:orderId/accept              — Accept order (→ VENDOR_ACCEPTED)
 *   POST   /:orderId/reject              — Reject order (→ VENDOR_REJECTED)
 *   POST   /:orderId/processing-stage    — Update processing stage
 *   POST   /:orderId/reconcile           — Receipt reconciliation
 */
export default async function vendorOrdersRoutes(fastify) {
  const service = new VendorOrdersService()
  const controller = new VendorOrdersController(service)

  // All routes require authentication
  fastify.addHook('preHandler', fastify.authenticate)

  const orderIdParams = {
    type: 'object',
    required: ['orderId'],
    properties: {
      orderId: { type: 'string', format: 'uuid' }
    }
  }

  // GET / — List vendor orders
  fastify.get('/', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'List orders for this vendor',
      security: [{ bearerAuth: [] }],
      querystring: {
        type: 'object',
        properties: {
          status: {
            type: 'string',
            enum: [
              'WAITING_VENDOR_CONFIRMATION', 'VENDOR_ACCEPTED',
              'PICKUP_ASSIGNED', 'GOING_FOR_PICKUP', 'PICKUP_OTP_VERIFIED', 'PICKED_UP',
              'RECEIVED_AT_VENDOR', 'WASHING', 'DRYING', 'IRONING', 'PACKED',
              'DELIVERY_ASSIGNED', 'OUT_FOR_DELIVERY', 'DELIVERY_OTP_VERIFIED', 'DELIVERED',
              'VENDOR_REJECTED', 'AUTO_REJECTED', 'CUSTOMER_CANCELLED', 'ADMIN_CANCELLED', 'REFUNDED'
            ]
          },
          page: { type: 'integer', minimum: 1, default: 1 },
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 }
        }
      }
    }
  }, controller.listOrders.bind(controller))

  // GET /stats — Dashboard stats
  fastify.get('/stats', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Get vendor dashboard order statistics',
      security: [{ bearerAuth: [] }]
    }
  }, controller.getDashboardStats.bind(controller))

  // GET /:orderId — Order detail
  fastify.get('/:orderId', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Get vendor order details',
      security: [{ bearerAuth: [] }],
      params: orderIdParams
    }
  }, controller.getOrder.bind(controller))

  // POST /:orderId/accept — Accept order
  fastify.post('/:orderId/accept', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Vendor accepts order',
      security: [{ bearerAuth: [] }],
      params: orderIdParams
    }
  }, controller.acceptOrder.bind(controller))

  // POST /:orderId/reject — Reject order
  fastify.post('/:orderId/reject', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Vendor rejects order',
      security: [{ bearerAuth: [] }],
      params: orderIdParams,
      body: {
        type: 'object',
        properties: {
          reason: { type: 'string', maxLength: 500 }
        }
      }
    }
  }, controller.rejectOrder.bind(controller))

  // POST /:orderId/processing-stage — Update processing stage
  fastify.post('/:orderId/processing-stage', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Update order processing stage (WASHING, DRYING, IRONING, PACKED)',
      security: [{ bearerAuth: [] }],
      params: orderIdParams,
      body: {
        type: 'object',
        required: ['status'],
        properties: {
          status: {
            type: 'string',
            enum: ['RECEIVED_AT_VENDOR', 'WASHING', 'DRYING', 'IRONING', 'PACKED']
          }
        }
      }
    }
  }, controller.updateProcessingStage.bind(controller))

  // POST /:orderId/reconcile — Receipt reconciliation
  fastify.post('/:orderId/reconcile', {
    schema: {
      tags: ['Vendor Orders'],
      summary: 'Reconcile garment count/weight after receiving order',
      security: [{ bearerAuth: [] }],
      params: orderIdParams,
      body: {
        type: 'object',
        properties: {
          confirmed_lines: {
            type: 'array',
            items: {
              type: 'object',
              required: ['garment_type_id', 'confirmed_quantity'],
              properties: {
                garment_type_id: { type: 'string', format: 'uuid' },
                confirmed_quantity: { type: 'integer', minimum: 0 }
              }
            }
          },
          confirmed_weight_kg: { type: 'number', minimum: 0.1 },
          adjustment_reason: { type: 'string', maxLength: 500 }
        }
      }
    }
  }, controller.reconcileReceipt.bind(controller))
}
