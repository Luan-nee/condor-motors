import express from 'express'
import path from 'node:path'
import { envs } from './config/envs'

const port = envs.SERVER_PORT

const app = express()

app.use(express.static(path.join(process.cwd(), 'client-build')))

app.get('*', (_, res) => {
  res.sendFile(path.join(process.cwd(), 'client-build', 'index.html'))
})

app.listen(port, () => {
  console.log(`Server running on port http://localhost:${port}`)
})
