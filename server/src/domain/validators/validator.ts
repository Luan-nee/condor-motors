export class Validator {
  static isOnlyLetters = (val: string) => /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$/.test(val)

  static isOnlyNumbers = (val: string) => /^\d+$/.test(val)
}
