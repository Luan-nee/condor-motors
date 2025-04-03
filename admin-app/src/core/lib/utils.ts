export const debounce = (callback: (...args: any[]) => void, delay: number) => {
  let timeoutId: ReturnType<typeof setTimeout> | undefined
  return (...args: any[]) => {
    if (timeoutId) clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      callback.apply(null, args)
    }, delay)
  }
}

export const delay = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms))

export const selectWith = <T extends HTMLElement>(
  selector: string,
  parent: ParentNode = document
): T => {
  const $element = parent.querySelector(selector)
  if ($element == null) {
    throw new Error(`Element not found with selector: ${selector}`)
  }

  if (!($element instanceof HTMLElement)) {
    throw new Error(`Element is not an instance of HTMLElement`)
  }

  return $element as T
}

export const selectSvgWith = <T extends SVGElement>(
  selector: string,
  parent: ParentNode = document
): T => {
  const $element = parent.querySelector(selector)
  if ($element == null) {
    throw new Error(`SVG element not found with selector: ${selector}`)
  }

  if (!($element instanceof SVGElement)) {
    throw new Error(`Element is not an instance of SVGElement`)
  }

  return $element as T
}

export const $all = (selector: string) => document.querySelectorAll(selector)

export const validateAndFormatFileName = (value: string) => {
  const maxLength = 255
  const invalidCharacters = /[\\/:*?"<>|]/

  if (!value) {
    throw new Error('El nombre del archivo no puede estar vacío.')
  }

  if (value.length > maxLength) {
    throw new Error(
      `El nombre del archivo no puede exceder los ${maxLength} caracteres.`
    )
  }

  if (invalidCharacters.test(value)) {
    throw new Error('El nombre del archivo contiene caracteres inválidos.')
  }

  return value
    .trim()
    .replace(/[\s]+/g, '_')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/(^-|-$)/g, '')
    .replace(/-+/g, '-')
}

export const readFileFromInput = (input: HTMLInputElement) => {
  let selectedFile: File | null = null

  requestIdleCallback(() => {
    if (input.files == null || input.files[0] == null) {
      return {
        error: {
          message: 'No se ha seleccionado un archivo'
        }
      }
    }

    const [file] = input.files

    if (file.size > 150 * 1024 * 1024) {
      return {
        error: {
          message: `El archivo no puede pesar más de 150 MB (peso del archivo actual: ${(file.size * 1024 * 1024).toFixed(2)} MB)`
        }
      }
    }

    if (file.type === '' && file.name.endsWith('.apk')) {
      selectedFile = new File([file], file.name, {
        type: 'application/vnd.android.package-archive'
      })
    }

    selectedFile = file
  })

  return selectedFile
}

export const getFileSize = (size: number) => {
  if (size < 1e3) {
    return `${size} bytes`
  } else if (size >= 1e3 && size < 1e6) {
    return `${(size / 1e3).toFixed(2)} KB`
  }

  return `${(size / 1e6).toFixed(2)} MB`
}
