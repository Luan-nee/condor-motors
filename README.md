<div align="center"><img src="assets/condor-motors-logo.webp" alt="Condor motors" style="width: 300px; height: 300px;">

[![Node.js Version](https://img.shields.io/badge/node-%3E%3D%2020.0.0-brightgreen)](https://nodejs.org)
[![NPM Version](https://img.shields.io/badge/npm-%3E%3D%208.0.0-blue)](https://www.npmjs.com)
[![License: ISC](https://img.shields.io/badge/License-ISC-yellow.svg)](https://opensource.org/licenses/ISC)

</div>

## 📋 Descripción

Solución completa para la gestión de:

- 👥 Empleados
- 📦 Inventario
- 💰 Facturación

El proyecto está estructurado como un monorepo que contiene:

- 🖥️ **Cliente**: Interfaz de usuario moderna y responsive desarrollada con React
- ⚙️ **Servidor**: API RESTful robusta construida con Node.js y PostgreSQL

## 🚀 Inicio Rápido

### Prerrequisitos

- Node.js (>= 20.0.0)
- npm (>= 8.0.0)
- PostgreSQL

### Instalación

1. Clona el repositorio

```bash
git clone git@github.com:Luan-nee/CondorMotors.git
cd CondorMotors
```

2. Instala las dependencias

```bash
npm install
```

3. Configura las variables de entorno

```bash
cp client/.env.template client/.env
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
```

5. Inicia el desarrollo

```bash
# Terminal 1 - Cliente
npm run dev:client

# Terminal 2 - Servidor
npm run dev:server
```

## 🛠️ Scripts Disponibles

### Cliente (Frontend)

| Comando                  | Descripción                      |
| ------------------------ | -------------------------------- |
| `npm run dev:client`     | Inicia el servidor de desarrollo |
| `npm run build:client`   | Genera la build de producción    |
| `npm run lint:client`    | Ejecuta el linter                |
| `npm run preview:client` | Previsualiza la build            |

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

| Comando               | Descripción                               |
| --------------------- | ----------------------------------------- |
| `npm run db:generate` | Genera archivos de migración              |
| `npm run db:migrate`  | Ejecuta las migraciones pendientes        |
| `npm run db:push`     | Sincroniza el esquema de la base de datos |

### Globales

| Comando         | Descripción                      |
| --------------- | -------------------------------- |
| `npm run build` | Construye cliente y servidor     |
| `npm run start` | Inicia el servidor en producción |

## ⚙️ Configuración

### Variables de Entorno

#### Cliente (`client/.env`)

```dotenv
VITE_PORT=3001  # Puerto para el servidor de desarrollo
```

#### Servidor (`server/.env`)

```dotenv
SERVER_PORT=3000  # Puerto para la API
DATABASE_URL='postgres://user:password@host:port/db'  # URL de conexión a PostgreSQL
JWT_SEED=your-secret-seed  # Semilla para JWT (mínimo 12 caracteres)
```

## 🏗️ Estructura del Proyecto

```sh
CondorMotors/
├── client/          # Frontend React
├── server/          # Backend Node.js
├── package.json     # Configuración del monorepo
└── README.md
```
