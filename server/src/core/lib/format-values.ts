export const formatCode = (value: string) =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')

export const formatFileName = (value: string) =>
  value
    .trim()
    .replace(/[\s]+/g, '_')
    .replace(/[^a-zA-Z0-9._-]/g, '')
    .replace(/[-_]+/g, '_')
    .replace(/(^[-_]|[-_]$)/g, '')
