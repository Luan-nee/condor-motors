import sharp from 'sharp'

interface ImageValidatorOptions {
  maxWidth: number
  maxHeight: number
}

export const imageValidator = async (
  file: Express.Multer.File,
  options: ImageValidatorOptions
) => {
  const metadata = await sharp(file.buffer).metadata()

  if (
    metadata.format !== 'jpeg' &&
    metadata.format !== 'jpg' &&
    metadata.format !== 'png' &&
    metadata.format !== 'webp'
  ) {
    return 'Invalid file type. Only JPEG, JPG, PNG, and GIF are allowed'
  }

  if (
    metadata.width == null ||
    metadata.height == null ||
    metadata.width > options.maxWidth ||
    metadata.height > options.maxHeight
  ) {
    return `La imagen debe tener menos de ${options.maxWidth}x${options.maxHeight}px de ancho y de alto`
  }
}
