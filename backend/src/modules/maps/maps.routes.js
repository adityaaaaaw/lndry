import axios from 'axios'
import { success, error } from '../../utils/apiResponse.js'
import { env } from '../../config/env.js'

export default async function mapsRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticate)

  fastify.get('/place-autocomplete', {
    schema: {
      tags: ['Maps'],
      summary: 'Proxy Google Places Autocomplete',
      security: [{ bearerAuth: [] }],
      query: {
        type: 'object',
        required: ['query'],
        properties: {
          query: { type: 'string' },
          session_token: { type: 'string' },
          location_bias: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { query: input, session_token, location_bias } = request.query
    const apiKey = process.env.GOOGLE_MAPS_API_KEY || env.GOOGLE_MAPS_API_KEY

    if (!apiKey) {
      return reply.code(400).send(error('Google Maps API key is missing', 'CONFIG_ERROR'))
    }

    try {
      const params = {
        input,
        key: apiKey,
        types: 'geocode|establishment'
      }
      if (session_token) params.sessiontoken = session_token
      if (location_bias) {
        params.location = location_bias
        params.radius = 5000 // 5km bias
      }

      const response = await axios.get('https://maps.googleapis.com/maps/api/place/autocomplete/json', { params })
      if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
        throw new Error(response.data.error_message || `Google Places Autocomplete failed: ${response.data.status}`)
      }

      const suggestions = (response.data.predictions || []).map(p => ({
        description: p.description,
        place_id: p.place_id
      }))

      return reply.code(200).send(success(suggestions, 'Autocomplete suggestions fetched'))
    } catch (err) {
      request.log.error({ err }, 'Google Places Autocomplete error')
      return reply.code(500).send(error('Failed to fetch place suggestions', 'MAPS_ERROR'))
    }
  })

  fastify.get('/place-details/:placeId', {
    schema: {
      tags: ['Maps'],
      summary: 'Proxy Google Place Details',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        required: ['placeId'],
        properties: {
          placeId: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { placeId } = request.params
    const apiKey = process.env.GOOGLE_MAPS_API_KEY || env.GOOGLE_MAPS_API_KEY

    if (placeId.startsWith('mock_place_')) {
      return reply.code(400).send(error('Mock addresses are disabled in this environment', 'CONFIG_ERROR'))
    }

    if (!apiKey) {
      return reply.code(400).send(error('Google Maps API key is missing', 'CONFIG_ERROR'))
    }

    try {
      const response = await axios.get('https://maps.googleapis.com/maps/api/place/details/json', {
        params: {
          place_id: placeId,
          key: apiKey,
          fields: 'formatted_address,geometry,address_components'
        }
      })

      if (response.data.status !== 'OK') {
        throw new Error(response.data.error_message || `Google Place Details failed: ${response.data.status}`)
      }

      const result = response.data.result
      const addressComponents = result.address_components || []
      const pincodeComponent = addressComponents.find(c => c.types.includes('postal_code'))

      const details = {
        formatted_address: result.formatted_address,
        lat: result.geometry?.location?.lat,
        lng: result.geometry?.location?.lng,
        postal_code: pincodeComponent ? pincodeComponent.long_name : null
      }

      return reply.code(200).send(success(details, 'Place details fetched'))
    } catch (err) {
      request.log.error({ err }, 'Google Place Details error')
      return reply.code(500).send(error('Failed to fetch place details', 'MAPS_ERROR'))
    }
  })
}
