export class UpdateMarcasDto {
  private constructor(
    public readonly id: number,
    public readonly nombre: string,
    public readonly descripcion?: string
  ) {}

  static create(props: Record<string, any>): [string?, UpdateMarcasDto?] {
    const { id, nombre, descripcion } = props

    if (typeof id !== 'number' || Number.isNaN(id) || id <= 0) {
      return ['El ID es requerido y debe ser un número válido']
    }

    if (typeof nombre !== 'string' || nombre.length === 0) {
      return ['El nombre es requerido']
    }

    return [undefined, new UpdateMarcasDto(id, nombre, descripcion)]
  }
}
