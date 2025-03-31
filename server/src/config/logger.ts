/* eslint-disable no-console */
import { isProduction } from '@/consts'
import type { Request, Response } from 'express'
import fs from 'fs'
import path from 'path'

interface Logger {
  info: (message: string) => void
  error: (message: string) => void
}

class ConsoleLogger implements Logger {
  info(message: string): void {
    console.info(message)
  }

  error(message: string): void {
    console.error(message)
  }
}

class FileLogger implements Logger {
  private readonly logFilePath: string
  private readonly errorLogFileName: string

  constructor(logFileName: string, errorLogFileName: string) {
    this.logFilePath = path.join(process.cwd(), 'logs/', logFileName)

    if (!fs.existsSync(path.dirname(this.logFilePath))) {
      fs.mkdirSync(path.dirname(this.logFilePath), { recursive: true })
    }

    this.errorLogFileName = path.join(process.cwd(), 'logs/', errorLogFileName)

    if (!fs.existsSync(path.dirname(this.errorLogFileName))) {
      fs.mkdirSync(path.dirname(this.errorLogFileName), { recursive: true })
    }
  }

  private writeLog(message: string, filePath: string) {
    const logMessage = `${message}\n`
    fs.appendFile(filePath, logMessage, { encoding: 'utf-8' }, (err) => {
      if (err != null) {
        console.error("Couldn't save the log")
      }
    })
  }

  info(message: string): void {
    this.writeLog(message, this.logFilePath)
  }

  error(message: string): void {
    this.writeLog(message, this.errorLogFileName)
  }
}

const createLogger = (): Logger => {
  if (!isProduction) {
    return new FileLogger('requests.log', 'errors.log')
  }

  return new ConsoleLogger()
}

export const CustomLogger = createLogger()

export const LogRequest = (req: Request, res: Response, duration: number) => {
  const resource = 'http://' + req.headers.host + req.baseUrl + req.url
  const ip = req.ip ?? 'NULL'
  const user = 'id:' + (req.authPayload?.id ?? 'NULL')
  const message = `${req.method} ${resource} ${req.protocol.toUpperCase()}/${req.httpVersion} ${res.statusCode} ${duration}ms`
  const meta = { ip, user }

  CustomLogger.info(message + JSON.stringify(meta))
}
