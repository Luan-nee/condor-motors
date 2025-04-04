interface ImportMetaEnv {
  readonly BASE_URL: string
  readonly PUBLIC_API_URL: string
  readonly MAX_UPLOAD_FILE_SIZE_MB: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
