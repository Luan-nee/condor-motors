import { CreateTrabajadorValidador } from "@/domain/validators/entities/trabajadores/trabajadores.validor"

export class CreateTrabajadorDto{
    public nombre :string
    public apellidos :string
    public edad?:number
    public dni:string //
    public horaInicioJornada : string
    public horaFinJornada : string
    public sueldo?: number
    public sucursalId : number 

    private constructor({
        nombre,
        apellidos,
        edad,
        dni,
        horaInicioJornada,
        horaFinJornada,
        sueldo,
        sucursalId,
    }: CreateTrabajadorDto ){
        this.nombre = nombre;
        this.apellidos = apellidos;
        this.edad = edad;
        this.dni = dni;
        this.horaInicioJornada = horaInicioJornada;
        this.horaFinJornada = horaFinJornada;
        this.sueldo = sueldo;
        this.sucursalId = sucursalId; 
    }
    static create(input: any ):[string?,CreateTrabajadorDto?]{
        const resultado = CreateTrabajadorValidador(input)

        if( !resultado.success ){
            return [resultado.error.message,undefined];
        }

        return [undefined,new CreateTrabajadorDto(resultado.data)]
    }
}