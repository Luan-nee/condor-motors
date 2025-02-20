import { CustomError } from '@domain/errors/custom.error'
import type { Response } from 'express'

export const handleError = (error: unknown, res: Response) => {
  if (error instanceof CustomError && error.statusCode !== 500) {
    res.status(error.statusCode).json({ error: error.message })
    return
  }

  // eslint-disable-next-line no-console
  console.error(error)
  res.status(500).json({ error: 'Internal Server Error' })
}
