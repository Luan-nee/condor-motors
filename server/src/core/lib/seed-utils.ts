import { productWithTwoDecimals } from '@/core/lib/utils'

export function calcularPrecioYDescuento(
  detalle: {
    cantidadMinimaDescuento: number | null
    cantidadGratisDescuento: number | null
    porcentajeDescuento: number | null
    precioVenta: string
    precioOferta: string | null
    liquidacion: boolean
  },
  cantidad: number
) {
  let precioUnitario = Number(detalle.precioVenta)
  const precioOriginal = precioUnitario
  const cantidadGratis = 0
  const descuento = 0
  const cantidadPagada = cantidad

  if (detalle.precioOferta !== null && detalle.liquidacion) {
    precioUnitario = Number(detalle.precioOferta)
  }

  if (
    detalle.cantidadMinimaDescuento === null ||
    cantidad < detalle.cantidadMinimaDescuento
  ) {
    return {
      precioUnitario,
      precioOriginal,
      cantidadGratis,
      descuento,
      cantidadPagada
    }
  }

  if (detalle.cantidadGratisDescuento !== null) {
    return {
      precioUnitario,
      precioOriginal,
      cantidadGratis: detalle.cantidadGratisDescuento,
      descuento,
      cantidadPagada: cantidad - detalle.cantidadGratisDescuento
    }
  }

  if (detalle.porcentajeDescuento !== null) {
    return {
      precioUnitario: productWithTwoDecimals(
        precioUnitario * (1 - detalle.porcentajeDescuento / 100),
        1
      ),
      precioOriginal,
      cantidadGratis,
      descuento: detalle.porcentajeDescuento,
      cantidadPagada
    }
  }

  return {
    precioUnitario,
    precioOriginal,
    cantidadGratis,
    descuento,
    cantidadPagada
  }
}
