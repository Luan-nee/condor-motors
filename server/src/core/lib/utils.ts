export const generateSequentialIds = (length: number) =>
  Array.from({ length }).map((_, i) => i + 1)

export const getRandomValueFromArray = <T>(values: T[]) =>
  values[Math.floor(Math.random() * values.length)]

export const getRandomNumber = (min: number, max: number) => {
  const minCeiled = Math.ceil(min)
  const maxFloored = Math.floor(max) + 1
  return Math.floor(Math.random() * (maxFloored - minCeiled) + minCeiled)
}
