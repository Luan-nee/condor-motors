import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import { formatFileName } from '@/core/lib/format-values'
import { getFileNameAndExtension } from '@/core/lib/utils'
import { Validator } from '@/domain/validators/validator'
import multer from 'multer'
import path from 'node:path'

const privateDiskStorage = multer.diskStorage({
  destination: function (_req, _file, callback) {
    callback(null, envs.PRIVATE_STORAGE_PATH)
  },
  filename: function (_req, file, callback) {
    if (!Validator.isValidFileName(file.originalname)) {
      callback(CustomError.badRequest('El nombre del archivo es inválido'), '')
    }

    const { basename, extension } = getFileNameAndExtension(file.originalname)
    const formattedName = formatFileName(basename).toLocaleLowerCase()
    const fileBasename = `${Date.now().toString(16)}-${formattedName}`.slice(
      0,
      250
    )

    callback(null, `${fileBasename}${extension}`)
  }
})

export class FilesMiddleware {
  static readonly image = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const allowedTypes = /jpeg|jpg|png|webp/

      const extName = allowedTypes.test(
        path.extname(file.originalname).toLowerCase()
      )

      const mimeType = allowedTypes.test(file.mimetype)

      if (extName && mimeType) {
        callback(null, true)
        return
      }

      callback(
        CustomError.badRequest(
          'Invalid file type. Only JPEG, JPG, and PNG are allowed'
        )
      )
    }
  })

  static readonly apkDesktopApp = multer({
    storage: privateDiskStorage,
    limits: { fileSize: envs.MAX_UPLOAD_FILE_SIZE_MB * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const allowedTypes = /apk|msi|msi|exe|pfx/

      const extName = allowedTypes.test(
        path.extname(file.originalname).toLowerCase()
      )

      if (extName) {
        callback(null, true)
        return
      }

      callback(
        CustomError.badRequest(
          'Invalid file type. Only .apk, .msi, .msix, .exe or .pfx files are allowed'
        )
      )
    }
  })
}
