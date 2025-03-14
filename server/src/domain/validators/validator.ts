export class Validator {
  static isOnlyLetters = (val: string) => /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$/.test(val)

  static isOnlyNumbers = (val: string) => /^\d+$/.test(val)

  static isOnlyLettersSpaces = (val: string) =>
    /^(?! )([a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+){0,3})$/.test(
      val
    )
}
