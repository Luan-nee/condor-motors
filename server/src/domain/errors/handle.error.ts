import type { Response } from 'express'
import { CustomError } from './custom.error'

export const handleError = (error: unknown, res: Response) => {
  if (error instanceof CustomError) {
    res.status(error.statusCode).json({ error: error.message })
    return
  }

  // eslint-disable-next-line no-console
  console.error(error)
  res.status(500).json({ error: 'Internal Server Error' })
}
