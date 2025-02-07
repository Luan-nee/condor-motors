<div align="center"><img src="assets/condor-motors-logo.webp" alt="Condor motors" style="max-width: 300px; width: 100%; height: auto;">

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
- ⚙️ **Servidor**: API RESTful robusta construida con Node.js

## 🚀 Inicio Rápido

### Prerrequisitos

- Node.js (última versión estable)
- npm (incluido con Node.js)
- MySQL (próximamente)

### Instalación

1. Clona el repositorio

```bash
git clone git@github.com:Luan-nee/CondorMotors.git
cd condor-motors
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

4. Inicia el desarrollo

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

| Comando                | Descripción                           |
| ---------------------- | ------------------------------------- |
| `npm run dev:server`   | Inicia el servidor en modo desarrollo |
| `npm run build:server` | Genera la build de producción         |
| `npm run start:server` | Inicia el servidor en producción      |

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
PORT=3000  # Puerto para la API
```

## 🏗️ Estructura del Proyecto

```sh
condor-motors/
├── client/          # Frontend React
├── server/          # Backend Node.js
├── package.json     # Configuración del monorepo
└── README.md
```
