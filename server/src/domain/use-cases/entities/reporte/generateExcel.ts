import ExcelJS from 'exceljs'

async function createExcelFile() {
  const workbook = new ExcelJS.Workbook()
  const worksheet = workbook.addWorksheet('Datos')

  worksheet.columns = [
    { header: 'ID', key: 'id', width: 10 },
    { header: 'SKU', key: 'sku', width: 15 },
    { header: 'Nombre', key: 'name', width: 30 },
    { header: 'DESCRIPCION', key: 'desc', width: 30 },a
    { header: 'stockMinimo', key: 'minimo', width: 10 },
    { header: 'Cantidad Descuento', key: 'descuento', width: 10 },
    { header: '' }
  ]

  worksheet.addRow({ id: 1, name: 'Juan', age: 25 })
  worksheet.addRow({ id: 2, name: 'María', age: 30 })

  await workbook.xlsx.writeFile('storage/private/reportes/archivo.xlsx')
}

// export createExcelFile;
