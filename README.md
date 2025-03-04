# Condor Motors

<div align="center">

![Condor motors](readme-assets/condor-motors-logo.webp)

[![Node.js Version](https://img.shields.io/badge/node-%3E%3D%2020.0.0-brightgreen)](https://nodejs.org)
[![NPM Version](https://img.shields.io/badge/npm-%3E%3D%208.0.0-blue)](https://www.npmjs.com)
[![License: ISC](https://img.shields.io/badge/License-ISC-yellow.svg)](https://opensource.org/licenses/ISC)

</div>

## 📋 Descripción

Solución completa para la gestión de:

- 👥 Empleados
- 📦 Inventario
- 💰 Facturación

El proyecto está construido con:

- ⚙️ **Backend**: API RESTful robusta construida con Node.js y PostgreSQL

## 🚀 Inicio Rápido

### Prerrequisitos

- Node.js (>= 20.0.0)
- npm (>= 8.0.0)
- PostgreSQL

### Instalación

1. Clona el repositorio

   ```bash
   git clone git@github.com:Luan-nee/CondorMotors.git
   cd condorMotors
   ```

2. Instala las dependencias

   ```bash
   npm install
   ```

3. Configura las variables de entorno

   ```bash
   cp server/.env.template server/.env
   ```

4. Configura la base de datos

   ```bash
   # Genera los archivos de migración
   npm run db:generate

   # Aplica las migraciones
   npm run db:migrate

   # O alternativamente, sincroniza el esquema directamente
   npm run db:push

   # Opcional: Poblar la base de datos con datos de prueba
   npm run db:seed
   ```

5. Inicia el desarrollo

   ```bash
   npm run dev:server
   ```

## 🛠️ Scripts Disponibles

### Servidor (Backend)

| Comando                     | Descripción                                 |
| --------------------------- | ------------------------------------------- |
| `npm run dev:server`        | Inicia el servidor en modo desarrollo       |
| `npm run build:server`      | Genera la build de producción               |
| `npm run start:server`      | Inicia el servidor en producción            |
| `npm run type-check:server` | Verifica los tipos de TypeScript            |
| `npm run init:server`       | Inicializa las configuraciones del servidor |
| `npm run lint:server`       | Ejecuta el linter                           |

### Base de Datos

| Comando               | Descripción                                 |
| --------------------- | ------------------------------------------- |
| `npm run db:generate` | Genera archivos de migración                |
| `npm run db:migrate`  | Ejecuta las migraciones pendientes          |
| `npm run db:push`     | Sincroniza el esquema de la base de datos   |
| `npm run db:seed`     | Inserta datos de prueba                     |
| `npm run db:reset`    | Reinicia la base de datos                   |
| `npm run db:populate` | Puebla la base de datos con datos iniciales |

## ⚙️ Configuración

### Variables de Entorno

#### Servidor (`server/.env`)

```dotenv
# Modo del entorno
NODE_ENV=development

# Puerto para la API
SERVER_PORT=3000

# URL de conexión a PostgreSQL
DATABASE_URL='postgres://user:password@host:port/db'

# Semilla para JWT (mínimo 12 caracteres)
JWT_SEED=your-secret-seed

# Duración del refresh token (en segundos, default: 7 días)
REFRESH_TOKEN_DURATION=604800

# Duración del access token (en segundos, default: 30 minutos)
ACCESS_TOKEN_DURATION=1800
```

## 🏗️ Estructura del Proyecto

```sh
CondorMotors/
├── server/          # Backend Node.js
│   ├── src/         # Código fuente
│   ├── build/       # Código compilado
│   └── package.json # Configuración del servidor
├── package.json     # Configuración del proyecto
└── README.md
```
