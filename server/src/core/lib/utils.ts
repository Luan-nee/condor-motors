import type { permissionCodes } from '@/consts'

export const generateSequentialIds = (length: number) =>
  Array.from({ length }).map((_, i) => i + 1)

export const getRandomValueFromArray = <T>(values: T[]) =>
  values[Math.floor(Math.random() * values.length)]

export const getRandomNumber = (min: number, max: number) => {
  const minCeiled = Math.ceil(min)
  const maxFloored = Math.floor(max) + 1
  return Math.floor(Math.random() * (maxFloored - minCeiled) + minCeiled)
}

export const transformPermissionCodes = (codes: typeof permissionCodes) =>
  Object.values(codes).flatMap((category) =>
    Object.values(category).map((code) => ({
      nombrePermiso: code,
      codigoPermiso: code
    }))
  )

export const transformPermissionsCodesFromArray = (permisos: string[]) =>
  permisos.map((permiso) => ({
    nombrePermiso: permiso,
    codigoPermiso: permiso
  }))
