import { CreateTrabajadorValidador } from "@/domain/validators/entities/trabajadores/trabajadores.validor"

export class CreateTrabajadorDto{
    public nombre:string
    public apellido:string
    public edad:Number
    public DNI:string
    public H_inicio:number
    public H_Final:number
    public Sueldo?:Number
    public SucursalPuesto:Number

    private constructor({
        nombre,
        apellido,
        edad,
        DNI,
        H_inicio,
        H_Final,
        Sueldo,
        SucursalPuesto
    }: CreateTrabajadorDto ){
        this.nombre = nombre;
        this.apellido = apellido;
        this.DNI = DNI;
        this.edad = edad;
        this.H_inicio = H_inicio;
        this.H_Final = H_Final;
        this.Sueldo = Sueldo;
        this.SucursalPuesto = SucursalPuesto;
    }
    static create(input: any ):[string?,CreateTrabajadorDto?]{
        const resultado = CreateTrabajadorValidador(input)

        if( !resultado.success ){
            return [resultado.error.message,undefined];
        }

        return [undefined,new CreateTrabajadorDto(resultado.data)]
    }
}