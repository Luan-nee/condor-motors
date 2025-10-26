import pino, { type Logger } from 'pino'
import { envs } from './envs'

interface MessageWithContext {
  message: string
  context?: Record<string, unknown>
}

type SimpleMessage = string

export type Message = SimpleMessage | MessageWithContext

export interface ILogger {
  debug: (message: Message) => void
  info: (message: Message) => void
  warn: (message: Message) => void
  error: (message: Message) => void
  fatal: (message: Message) => void
}

export class PinoLoggerAdapter implements ILogger {
  private readonly logger: Logger

  constructor(options?: pino.LoggerOptions) {
    this.logger = pino({
      level: envs.LOG_LEVEL,
      transport:
        envs.NODE_ENV === 'development'
          ? {
              target: 'pino-pretty',
              options: {
                colorize: true,
                translateTime: 'HH:MM:ss Z',
                ignore: 'pid,hostname'
              }
            }
          : undefined,
      ...options
    })
  }

  private formatMessage(message: Message): {
    msg: string
    context?: Record<string, unknown>
  } {
    if (typeof message === 'string') {
      return { msg: message }
    }
    return { msg: message.message, context: message.context }
  }

  debug(message: Message): void {
    const { msg, context } = this.formatMessage(message)
    this.logger.debug(context, msg)
  }

  info(message: Message): void {
    const { msg, context } = this.formatMessage(message)
    this.logger.info(context, msg)
  }

  warn(message: Message): void {
    const { msg, context } = this.formatMessage(message)
    this.logger.warn(context, msg)
  }

  error(message: Message): void {
    const { msg, context } = this.formatMessage(message)
    this.logger.error(context, msg)
  }

  fatal(message: Message): void {
    const { msg, context } = this.formatMessage(message)
    this.logger.fatal(context, msg)
  }

  getPinoInstance(): Logger {
    return this.logger
  }
}

export const logger = new PinoLoggerAdapter()
