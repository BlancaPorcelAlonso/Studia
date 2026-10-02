# Studia

Studia es una agenda académica para organizar asignaturas, tareas, exámenes, entregas y apuntes desde una sola aplicación. Está desarrollada con Flutter y puede usarse desde la web o instalarse en dispositivos compatibles como una PWA.

## Funcionalidades

- Organizar asignaturas y consultar su progreso.
- Crear y gestionar tareas, exámenes, entregas y apuntes.
- Enlazar tareas con exámenes o entregas, y exámenes con apuntes.
- Consultar el calendario, la semana y el historial académico.
- Abrir archivos adjuntos desde la aplicación.
- Iniciar sesión y sincronizar los datos con Supabase.

## Requisitos

- Flutter SDK compatible con Dart `^3.5.0`.
- Para las funciones en la nube: un proyecto Supabase configurado para la aplicación.

## Ejecutar en local

Instala las dependencias y arranca la aplicación en Chrome:

```bash
flutter pub get
flutter run -d chrome
```

Para iniciar la aplicación con otra URL de Supabase, puedes pasarla mediante `dart-define`:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co
```

La configuración de Supabase está en `lib/services/supabase_config.dart`. La clave publishable configurada allí es una clave de cliente; las políticas de acceso y permisos de los datos deben configurarse en Supabase.

## Compilar la web

```bash
flutter build web --release
```

Los archivos listos para publicar se generan en `build/web`.

## Publicar en Netlify

El archivo `netlify.toml` configura la compilación con `flutter pub get && flutter build web --release`, publica `build/web` y redirige las rutas de la aplicación a `index.html`. Conecta el repositorio a Netlify para desplegarlo usando esa configuración.

## Instalar como PWA

La configuración de instalación se encuentra en:

- `web/manifest.json`: nombre, iconos y modo de visualización de Studia.
- `web/index.html`: metadatos web y compatibilidad de instalación en iOS.
- `netlify.toml`: publicación, cabeceras de caché y rutas de la aplicación.

La instalación se ofrece desde el navegador, no desde un botón dentro de Studia. En Android, abre la web publicada con Chrome y usa el menú para instalarla o añadirla a la pantalla de inicio. En iPhone/iPad, abre la web con Safari, toca **Compartir** y selecciona **Añadir a pantalla de inicio**. La web debe estar publicada mediante HTTPS.

Studia aún no implementa una estrategia de funcionamiento offline completo.
