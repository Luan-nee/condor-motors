/* eslint-disable no-console */
import { envs } from '@/config/envs'
import { isProduction } from '@/consts'
import { db } from '@db/connection'
import { sql } from 'drizzle-orm'
import { exit } from 'process'

const dropSchema = async (dbSchemas: string[]) => {
  const querys = dbSchemas.map((dbSchema) =>
    sql.raw(`
      DO $$
      DECLARE
        r RECORD;
      BEGIN
      FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = '${dbSchema}') LOOP
      EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
      END LOOP;
      END $$;
    `)
  )

  await db.transaction(async (tx) => {
    await Promise.all(
      querys.map(async (query) => {
        await tx.execute(query)
      })
    )
  })
}

const dbSchemas = ['public', 'drizzle']

const message =
  dbSchemas.length < 1
    ? 'No schema has been dropped'
    : dbSchemas.length === 1
      ? `${dbSchemas.join()} schema has been dropped correctly!`
      : dbSchemas.length === 2
        ? `${dbSchemas.join(' and ')} schemas have been dropped correctly!`
        : `${dbSchemas.join(', ')} schemas have been dropped correctly!`

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  dropSchema(dbSchemas)
    .then(() => {
      console.log(message)
      exit()
    })
    .catch((error: unknown) => {
      console.error(error)
      exit(1)
    })
} else {
  console.log(`Database not modified`)
  console.log(`You are in ${nodeEnv} enviroment`)
}
