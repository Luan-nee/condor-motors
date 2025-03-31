import { CustomError } from '@/core/errors/custom.error'
import multer from 'multer'
import path from 'node:path'

// const storage = multer.diskStorage({
//   destination: function (_req, _file, callback) {
//     callback(null, 'storage/public/static/img')
//   },
//   filename: function (_req, file, callback) {
//     const extension = path.extname(file.originalname).toLowerCase()
//
//     callback(null, `${Date.now()}${extension}`)
//   }
// })

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
}
