import type { permissionCodes } from '@/consts'

export const generateSequentialIds = (length: number) =>
  Array.from({ length }).map((_, i) => i + 1)

export const getRandomValueFromArray = <T>(array: T[]) =>
  array[Math.floor(Math.random() * array.length)]

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

export const fisherYatesShuffle = <T>(array: T[]) => {
  const newArray = array.slice()
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[newArray[i], newArray[j]] = [newArray[j], newArray[i]]
  }

  return newArray
}

export const getRandomUniqueElementsFromArray = <T>(
  array: T[],
  amount: number
) => {
  if (amount > array.length) {
    throw new Error(
      'El arreglo dado es más pequeño que la cantidad de elementos solicitados'
    )
  }
  return fisherYatesShuffle(array).slice(0, amount)
}
