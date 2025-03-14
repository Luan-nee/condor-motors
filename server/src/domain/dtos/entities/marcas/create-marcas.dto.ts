export class CreateMarcasDto {
  private constructor(
    public readonly nombre: string,
    public readonly descripcion?: string
  ) {}

  static create(props: Record<string, any>): [string?, CreateMarcasDto?] {
    const { nombre, descripcion } = props

    if (typeof nombre !== 'string' || nombre.length === 0) {
      return ['El nombre es requerido']
    }

    return [undefined, new CreateMarcasDto(nombre, descripcion)]
  }
}
