import type { fileTypeValues } from '@/core/consts'

export type FileTypeValues =
  (typeof fileTypeValues)[keyof typeof fileTypeValues]
