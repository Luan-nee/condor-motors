import { logger } from '@/config/logger'
import { access, constants, mkdir } from 'node:fs/promises'
import path from 'node:path'

export const createDirIfNotExists = async (...dirPaths: string[]) => {
  const dirPath = path.join(...dirPaths)

  try {
    await access(dirPath, constants.R_OK | constants.W_OK)
  } catch (error: any) {
    if (error?.code === 'ENOENT') {
      await mkdir(dirPath, { recursive: true })
      return
    }

    logger.error({
      message: `Error al verificar o crear el directorio ${dirPath}:`,
      context: { error }
    })

    if (error instanceof Error) {
      throw error
    }
  }
}
