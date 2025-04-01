/* eslint-disable no-console */
import { isProduction, logsDestination } from '@/consts'
import fs from 'fs'
import path from 'path'
import { envs } from './envs'

enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  FATAL = 'FATAL'
}

interface Logger {
  debug: (message: string, ...meta: any[]) => void
  info: (message: string, ...meta: any[]) => void
  warn: (message: string, ...meta: any[]) => void
  error: (message: string, ...meta: any[]) => void
  fatal: (message: string, ...meta: any[]) => void
}

class BaseLogger {
  protected formatLog(level: LogLevel, message: string, meta: any[]): string {
    const timestamp = new Date().toISOString()
    const metaString = meta.length > 0 ? JSON.stringify(meta) : ''
    return `[${timestamp}] [${level}] ${message} ${metaString}\n`
  }
}

class ConsoleLogger extends BaseLogger implements Logger {
  debug(message: string, ...meta: any[]): void {
    if (!isProduction) {
      console.debug(this.formatLog(LogLevel.DEBUG, message, meta))
    }
  }

  info(message: string, ...meta: any[]): void {
    console.info(this.formatLog(LogLevel.INFO, message, meta))
  }

  warn(message: string, ...meta: any[]): void {
    console.warn(this.formatLog(LogLevel.WARN, message, meta))
  }

  error(message: string, ...meta: any[]): void {
    console.error(this.formatLog(LogLevel.ERROR, message, meta))
  }

  fatal(message: string, ...meta: any[]): void {
    console.error(this.formatLog(LogLevel.FATAL, message, meta))
  }
}

class FileLogger extends BaseLogger implements Logger {
  private readonly logFilePath: string
  private readonly errorLogFilePath: string

  constructor(logFileName: string, errorLogFileName: string) {
    const logsDir = path.join(process.cwd(), 'logs/')
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true })
    }

    super()

    this.logFilePath = path.join(logsDir, logFileName)
    this.errorLogFilePath = path.join(logsDir, errorLogFileName)
  }

  private writeLog(
    level: LogLevel,
    message: string,
    meta: any[],
    filePath: string
  ) {
    const logMessage = this.formatLog(level, message, meta)
    fs.appendFile(filePath, logMessage, { encoding: 'utf-8' }, (err) => {
      if (err != null) {
        console.error("Couldn't save the log to file:", err)
      }
    })
  }

  debug(message: string, ...meta: any[]): void {
    this.writeLog(LogLevel.DEBUG, message, meta, this.logFilePath)
  }

  info(message: string, ...meta: any[]): void {
    this.writeLog(LogLevel.INFO, message, meta, this.logFilePath)
  }

  warn(message: string, ...meta: any[]): void {
    this.writeLog(LogLevel.WARN, message, meta, this.logFilePath)
  }

  error(message: string, ...meta: any[]): void {
    this.writeLog(LogLevel.ERROR, message, meta, this.errorLogFilePath)
  }

  fatal(message: string, ...meta: any[]): void {
    this.writeLog(LogLevel.FATAL, message, meta, this.errorLogFilePath)
  }
}

const createLogger = (type: string): Logger => {
  if (type === logsDestination.filesystem) {
    return new FileLogger('app.log', 'errors.log')
  }

  return new ConsoleLogger()
}

export const CustomLogger = createLogger(envs.LOGS)
