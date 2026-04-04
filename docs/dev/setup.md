# Setup del entorno de desarrollo

Guía paso a paso para configurar el entorno de desarrollo local del módulo **turnos-personal**.

## Requisitos previos

| Herramienta | Versión mínima | Instalación |
|------------|----------------|-------------|
| Flutter SDK | 3.19 | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.3 (incluido con Flutter) | – |
| Supabase CLI | 1.170 | `npm install -g supabase` |
| Docker Desktop | 24 | https://www.docker.com/products/docker-desktop |
| Android Studio / VS Code | Cualquiera reciente | Para emuladores Android |

## 1. Clonar el repositorio

```bash
git clone https://github.com/OscarDavids-Prog/turnos-personal.git
cd turnos-personal
```

## 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz (no commitear):

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

Solicitar las credenciales al administrador del sistema.

## 3. Supabase local

```bash
# Iniciar Supabase local (requiere Docker)
supabase start

# Aplicar todas las migraciones
supabase db reset

# Verificar que las tablas existen
supabase db diff
```

El Studio local estará disponible en `http://localhost:54323`.

## 4. App admin (Flutter)

```bash
cd apps/admin
flutter pub get
flutter run
```

Para correr en un emulador específico:

```bash
flutter devices           # listar dispositivos disponibles
flutter run -d <device>   # correr en dispositivo específico
```

## 5. APK empleados (Flutter)

```bash
cd apps/empleados
flutter pub get
flutter run
```

Para generar el APK de distribución:

```bash
flutter build apk --release
# El APK queda en: build/app/outputs/flutter-apk/app-release.apk
```

## 6. Verificar calidad de código

```bash
# Desde cada app
flutter analyze
flutter test
```

No se aceptan PRs con errores de `flutter analyze`.

## 7. Configurar Supabase en las apps

Las apps leen las credenciales desde `lib/services/supabase_service.dart`.  
Para desarrollo local, reemplazar temporalmente las URLs por las del ambiente local:

```dart
// Local
static const supabaseUrl = 'http://localhost:54321';
static const supabaseAnonKey = '<local-anon-key>';  // ver output de `supabase start`
```

> **Atención:** nunca commitear claves de producción en el código fuente.

## Estructura de carpetas de referencia

```
apps/
├── admin/
│   └── lib/
│       ├── main.dart
│       ├── models/
│       ├── providers/
│       ├── services/
│       └── screens/
└── empleados/
    └── lib/
        ├── main.dart
        ├── models/
        ├── services/
        └── screens/
```
