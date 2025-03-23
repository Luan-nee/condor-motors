import type { permissionCodes } from '@/consts'
import Big from 'big.js'

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
  for (let i = newArray.length - 1; i >= 0; i--) {
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

export const formatOffset = (offsetHours: number, offsetMinutes = 0) => {
  if (
    offsetHours < -12 ||
    offsetHours > 14 ||
    offsetMinutes < 0 ||
    offsetMinutes >= 60
  ) {
    return undefined
  }

  const sign = offsetHours >= 0 ? '+' : '-'
  const absHours = Math.abs(offsetHours)
  const absMinutes = Math.abs(offsetMinutes)

  return `${sign}${String(absHours).padStart(2, '0')}:${String(absMinutes).padStart(2, '0')}`
}

export const getOffsetDateTime = (
  dateTime: Date,
  offsetHours: number,
  offsetMinutes = 0
) => {
  if (
    !(dateTime instanceof Date) ||
    offsetHours < -12 ||
    offsetHours > 14 ||
    offsetMinutes < 0 ||
    offsetMinutes >= 60
  ) {
    return undefined
  }

  const offsetMillis = (offsetHours * 3600 + offsetMinutes * 60) * 1000
  const utcTime = dateTime.getTime() + offsetMillis
  const offsetDateTime = new Date(utcTime)

  return offsetDateTime
}

export const getDateTimeString = (dateTime: Date) => {
  const isoString = dateTime.toISOString()
  const date = isoString.substring(0, 10)
  const time = isoString.substring(11, 19)

  return {
    date,
    time
  }
}

export const productWithTwoDecimals = (num1: number, num2: number) =>
  new Big(num1).times(new Big(num2)).round(2).toNumber()

export const roundTwoDecimals = (num: number) =>
  new Big(num).round(2).toNumber()

export const fixedTwoDecimals = (num: number) => new Big(num).toFixed(2)
