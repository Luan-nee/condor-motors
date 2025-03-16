export class Validator {
  static isValidUsername = (val: string) => /^[a-zA-Z0-9\-_]+$/.test(val)

  static isValidPassword = (val: string) =>
    /^[a-zA-Z0-9$%&*_@#+\-_]+$/.test(val)

  static isOnlyNumbers = (val: string) => /^\d+$/.test(val)

  static isOnlyLettersSpaces = (val: string) =>
    /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+( [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)*$/.test(val)

  static isValidGeneralName = (val: string) =>
    /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\-_]+( [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\-_]+)*$/.test(val)

  static isValidAddress = (val: string) =>
    /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\-_.,]+( [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\-_.,]+)*$/.test(val)

  static isValidDescription = (val: string) =>
    /^[a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?\-()[\]{}$%&*'_"@#+]+(\s[a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ.,¡!¿?\-()[\]{}$%&*'_"@#+]+)*$/.test(
      val
    )
}
