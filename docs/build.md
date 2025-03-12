Te ayudaré a configurar los diferentes tipos de compilación y pruebas para la aplicación. Vamos paso a paso:

1. Primero, verificaré la configuración actual del proyecto:

Read file: CondorMotors/frontend/pubspec.yaml
Perfecto, vamos a configurar cada plataforma:

1. **Para Windows (Instalador):**

Primero, necesitamos configurar el MSIX installer. Agregaré la dependencia necesaria:

```yaml:CondorMotors/frontend/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.65.0
  cupertino_icons: ^1.0.8
  http: ^1.2.0
  dio: ^5.4.1
  mobile_scanner: ^3.5.6
  shared_preferences: ^2.5.2
  logging: ^1.3.0
  google_fonts: ^6.1.0
  local_auth: ^2.1.8
  flutter_secure_storage: ^9.0.0
  font_awesome_flutter: ^10.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  flutter_launcher_icons: ^0.13.1
  msix: ^3.16.7

# Configuración del instalador MSIX
msix_config:
  display_name: Condor Motors
  publisher_display_name: Condor Motors
  identity_name: com.condormotors.app
  msix_version: 1.0.0.0
  logo_path: assets/images/condor-motors-logo.webp
  capabilities: internetClient
// ... existing code ...
```
2. **Para Android (APK):**

La configuración para Android ya está lista en el pubspec.yaml. Ahora necesitamos configurar el archivo build.gradle para asegurarnos de que la compilación sea correcta.

Read file: CondorMotors/frontend/android/app/build.gradle
Ahora voy a crear un script que nos ayudará a compilar para todas las plataformas y configurar ngrok:

```powershell:CondorMotors/frontend/build.ps1
# Script de compilación para CondorMotors
param(
    [string]$platform = "all",
    [switch]$release = $false
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$text)
    Write-Host "`n=== $text ===`n" -ForegroundColor Cyan
}

function Build-Windows {
    Write-Header "Compilando para Windows"
    flutter clean
    flutter pub get
    
    if ($release) {
        Write-Host "Creando instalador MSIX..." -ForegroundColor Yellow
        flutter pub run msix:create
    } else {
        Write-Host "Compilando en modo debug..." -ForegroundColor Yellow
        flutter build windows
    }
}

function Build-Android {
    Write-Header "Compilando para Android"
    flutter clean
    flutter pub get
    
    if ($release) {
        Write-Host "Creando APK release..." -ForegroundColor Yellow
        flutter build apk --release
    } else {
        Write-Host "Creando APK debug..." -ForegroundColor Yellow
        flutter build apk --debug
    }
}

function Build-Web {
    Write-Header "Compilando para Web"
    flutter clean
    flutter pub get
    flutter build web

    Write-Host "Iniciando servidor web en el puerto 8080..." -ForegroundColor Yellow
    Start-Process flutter -ArgumentList "run", "-d", "web-server", "--web-port", "8080"
    
    Write-Host "Configurando ngrok..." -ForegroundColor Yellow
    # Verifica si ngrok está instalado
    if (!(Get-Command ngrok -ErrorAction SilentlyContinue)) {
        Write-Host "ngrok no está instalado. Por favor, instálalo desde https://ngrok.com/download" -ForegroundColor Red
        return
    }
    
    # Inicia ngrok
    Start-Process ngrok -ArgumentList "http", "8080"
}

# Función principal
switch ($platform.ToLower()) {
    "windows" { Build-Windows }
    "android" { Build-Android }
    "web" { Build-Web }
    "all" {
        Build-Windows
        Build-Android
        Build-Web
    }
    default {
        Write-Host "Plataforma no válida. Use: windows, android, web, o all" -ForegroundColor Red
    }
}
```
Ahora te explicaré cómo usar el script para compilar para cada plataforma:

1. **Para Windows (Instalador MSIX)**:
```powershell
.\build.ps1 -platform windows -release
```
El instalador se generará en `build\windows\runner\Release`

2. **Para Android (APK)**:
```powershell
.\build.ps1 -platform android -release
```
El APK se generará en `build\app\outputs\flutter-apk\app-release.apk`

3. **Para Web + ngrok**:
```powershell
.\build.ps1 -platform web
```
Esto:
- Compilará la aplicación web
- Iniciará un servidor local en el puerto 8080
- Iniciará ngrok y te dará una URL pública

**Requisitos previos:**
1. Tener instalado Flutter y Dart
2. Para Windows: Visual Studio con el workload de "Desktop development with C++"
3. Para Android: Android Studio y el SDK de Android
4. Para ngrok: Descargar e instalar ngrok desde https://ngrok.com/download

**Notas importantes:**
1. Para el instalador de Windows, asegúrate de tener un certificado digital o usar uno de desarrollo
2. Para el APK de release, necesitarás configurar la firma del APK en `android/app/build.gradle`
3. Para ngrok, necesitarás autenticarte la primera vez con:
```powershell
ngrok authtoken TU_TOKEN
```

¿Necesitas ayuda con alguno de estos pasos o quieres que profundicemos en alguna plataforma específica?
