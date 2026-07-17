import { buildApp } from './app.js'
import { env } from './config/env.js'
import { testConnection, closePool } from './config/database.js'
import { closeRedis } from './config/redis.js'
import { logger } from './config/logger.js'
import { runPermissionAudit } from './utils/permission-audit.js'
import { startCampaignScheduler, stopCampaignScheduler } from './workers/campaign-scheduler.worker.js'
import { startPaymentExpiryWorker, stopPaymentExpiryWorker } from './workers/payment-expiry.worker.js'
import http from 'http'
import { execSync } from 'child_process'

const checkPortGracefully = (port, host) => {
  return new Promise((resolve) => {
    const clientRequest = http.get(`http://${host}:${port}/health`, (res) => {
      let data = ''
      res.on('data', (chunk) => { data += chunk })
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data)
          if (res.statusCode === 200 && parsed.status === 'OK') {
            resolve({ occupied: true, healthy: true })
            return
          }
        } catch (_) {}
        resolve({ occupied: true, healthy: false, status: res.statusCode, data })
      })
    })

    clientRequest.on('error', (err) => {
      if (err.code === 'ECONNREFUSED') {
        resolve({ occupied: false })
      } else {
        resolve({ occupied: true, healthy: false, error: err.message })
      }
    })

    clientRequest.setTimeout(2000, () => {
      clientRequest.destroy()
      resolve({ occupied: true, healthy: false, error: 'Timeout' })
    })
  })
}

const validateProductionConfig = () => {
  if (env.NODE_ENV === 'production') {
    const missing = []
    if (!env.RAZORPAY_KEY_ID) missing.push('RAZORPAY_KEY_ID')
    if (!env.RAZORPAY_KEY_SECRET) missing.push('RAZORPAY_KEY_SECRET')
    if (!env.RAZORPAY_WEBHOOK_SECRET) missing.push('RAZORPAY_WEBHOOK_SECRET')
    if (!env.GOOGLE_MAPS_API_KEY) missing.push('GOOGLE_MAPS_API_KEY')

    if (missing.length > 0) {
      logger.error(`❌ Critical production configuration keys are missing: ${missing.join(', ')}`)
      process.exit(1)
    }
  }
}

// Trigger nodemon reload 2
const start = async () => {
  try {
    const port = env.PORT || 4500
    const rawHost = env.HOST || '0.0.0.0'
    const checkHost = rawHost === '0.0.0.0' ? '127.0.0.1' : rawHost

    const checkResult = await checkPortGracefully(port, checkHost)
    if (checkResult.occupied) {
      if (checkResult.healthy) {
        logger.info(`[PORT GUARD] Unified Backend is already running on port ${port}.`)
        logger.info(`[PORT GUARD] Skipping startup to avoid duplicate Node/Nodemon instances.`)
        process.exit(0)
      } else {
        logger.error(`❌ Port ${port} is occupied by another application or an unhealthy process.`)
        try {
          const netstatOutput = execSync(`netstat -ano | findstr :${port}`, { encoding: 'utf8' })
          const lines = netstatOutput.trim().split('\n')
          let pid = null
          for (const line of lines) {
            if (line.includes('LISTENING')) {
              const parts = line.trim().split(/\s+/)
              pid = parts[parts.length - 1]
              break
            }
          }
          if (pid) {
            logger.error(`Occupying Process ID (PID): ${pid}`)
            try {
              const procOutput = execSync(
                `powershell.exe -Command "Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}' | Select-Object ProcessId, ExecutablePath, CommandLine | Format-List"`,
                { encoding: 'utf8' }
              )
              logger.error(`Process details:\n${procOutput.trim()}`)
            } catch (procErr) {
              logger.error(`Failed to get process details: ${procErr.message}`)
            }
          }
        } catch (netstatErr) {
          logger.error(`Failed to run port diagnostics: ${netstatErr.message}`)
        }
        logger.fatal(`Health check result: ${checkResult.error || `HTTP ${checkResult.status}`}`)
        logger.fatal(`👉 Please terminate the occupying process before retrying.`)
        process.exit(1)
      }
    }

    validateProductionConfig()

    // Test database connection before starting
    await testConnection()

    // Build Fastify app
    const app = await buildApp()

    // ─── BOOT-TIME PERMISSION AUDIT (R17 AC#9, task 2.7) ───────────
    // After every plugin and module route has been registered, ensure
    // each protected dashboard route declares a canonical Permission_String
    // (design §4.5). `app.ready()` flushes all pending registrations so
    // every onRoute hook callback has fired into `app.permissionAuditRoutes`.
    // When STRICT_PERMISSION_AUDIT is true and any violation is found, abort
    // boot with exit code 1 per R17 AC#9; otherwise log a warning so the
    // misconfiguration stays visible while Phase C wires permissions in.
    await app.ready()
    const audit = runPermissionAudit({
      collectedRoutes: app.permissionAuditRoutes,
      strict: env.STRICT_PERMISSION_AUDIT,
      logger,
    })
    if (!audit.ok) {
      // Logged at error level inside runPermissionAudit. Close the
      // half-built app to release sockets and DB clients before exit so
      // graceful shutdown observers do not see a stuck process.
      await app.close().catch(() => {})
      await closePool().catch(() => {})
      await closeRedis().catch(() => {})
      process.exit(1)
    }

    // Start listening
    await app.listen({ port: env.PORT, host: env.HOST })

    logger.info(`🚀 ${env.APP_NAME} running on http://${env.HOST}:${env.PORT}`)
    if (env.ENABLE_SWAGGER) {
      logger.info(`📖 Swagger docs at http://localhost:${env.PORT}/documentation`)
    }
    if (app.io) {
      logger.info(`🔌 Socket.IO ready on ws://${env.HOST}:${env.PORT}`)
    }

    // Start campaign scheduler poller
    startCampaignScheduler()

    // Start payment expiry worker (cleans up abandoned 15-min payment windows)
    startPaymentExpiryWorker()

    // PM2 ready signal
    if (process.send) {
      process.send('ready')
    }

    // ─── GRACEFUL SHUTDOWN ──────────────────────────
    const shutdown = async (signal) => {
      logger.info({ signal }, 'Shutdown signal received')

      // Stop campaign scheduler
      stopCampaignScheduler()

      // Stop payment expiry worker
      stopPaymentExpiryWorker()

      // Close Socket.IO
      if (app.io) {
        app.io.close()
        logger.info('Socket.IO closed')
      }

      // Stop accepting new connections
      await app.close()
      logger.info('Fastify closed')

      // Close database pool
      await closePool()
      logger.info('PostgreSQL pool closed')

      // Close Redis
      await closeRedis()
      logger.info('Redis closed')

      logger.info('Graceful shutdown complete')
      process.exit(0)
    }

    process.on('SIGINT', () => shutdown('SIGINT'))
    process.on('SIGTERM', () => shutdown('SIGTERM'))

    // Unhandled errors — log and exit
    process.on('unhandledRejection', (err) => {
      logger.fatal({ err }, 'Unhandled rejection')
      process.exit(1)
    })

    process.on('uncaughtException', (err) => {
      logger.fatal({ err }, 'Uncaught exception')
      process.exit(1)
    })
  } catch (err) {
    logger.fatal({ err }, 'Failed to start server')
    process.exit(1)
  }
}

start()
