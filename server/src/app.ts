import { envs } from '@/config/envs'
import express from 'express'
import path from 'node:path'

const { SERVER_PORT: serverPort } = envs

const app = express()

app.use(express.static(path.join(process.cwd(), 'client-build')))

app.get('*', (_, res) => {
  res.sendFile(path.join(process.cwd(), 'client-build', 'index.html'))
})

app.listen(serverPort, () => {
  // eslint-disable-next-line no-console
  console.log(`Server running on port http://localhost:${serverPort}`)
})
