import { productWithTwoDecimals } from '@/core/lib/utils'

interface ComputePriceOfferArgs {
  cantidad: number
  cantidadMinimaDescuento: number | null
  cantidadGratisDescuento: number | null
  porcentajeDescuento: number | null
  precioVenta: string
  precioOferta: string | null
  liquidacion: boolean
}

export function computePriceOffer({
  cantidad,
  cantidadMinimaDescuento,
  cantidadGratisDescuento,
  porcentajeDescuento,
  precioVenta,
  precioOferta,
  liquidacion
}: ComputePriceOfferArgs) {
  let price = parseFloat(precioVenta)
  let free = 0

  if (precioOferta !== null && liquidacion) {
    price = parseFloat(precioOferta)
  }

  if (cantidadMinimaDescuento === null || cantidad < cantidadMinimaDescuento) {
    return { price, free }
  }

  if (cantidadGratisDescuento !== null) {
    free = cantidadGratisDescuento
  } else if (porcentajeDescuento !== null) {
    price = productWithTwoDecimals(price, 1 - porcentajeDescuento / 100)
  }

  return {
    price,
    free
  }
}
