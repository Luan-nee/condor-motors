process.loadEnvFile('.env')

export const envs = {
  SERVER_PORT: Number(process.env.SERVER_PORT ?? 3000)
}
