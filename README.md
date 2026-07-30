# Cuchillas — control visual de desgaste

App Android 100% offline para comparar fotos de cuchillas en el tiempo.
Los datos y fotos viven solo en el teléfono (SQLite + almacenamiento interno).

## Cómo obtener el APK (vía recomendada: GitHub Actions)

Solo necesitas una cuenta gratuita de GitHub. La nube compila; la app nunca la necesita.

1. Entra a github.com y crea una cuenta gratis (si no tienes).
2. Crea un repositorio nuevo: botón **New**, nombre `cuchillas`, **Private**, botón **Create repository**.
3. En el repositorio: **Add file → Upload files**. Arrastra TODO el contenido de esta carpeta (incluida la carpeta `.github`; si no la ves, activa "ver archivos ocultos"). Botón **Commit changes**.
4. Pestaña **Actions** → verás "Compilar APK" ejecutándose (~5-8 min).
5. Al terminar en verde, entra a la ejecución → sección **Artifacts** → descarga `cuchillas-apk`.
6. Descomprime el ZIP, pasa `app-release.apk` al teléfono (cable o Quick Share).
7. En el teléfono, toca el APK → acepta "instalar apps de origen desconocido" → instalar.

Para futuras versiones: subes los archivos modificados al repositorio y repites los pasos 4-6.

## Alternativa: compilar en tu PC

1. Instala Flutter: https://docs.flutter.dev/get-started/install/windows (incluye Android Studio).
2. En esta carpeta:
   ```
   flutter create . --platforms android --project-name cuchillas
   flutter pub get
   flutter build apk --release
   ```
3. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Con el teléfono conectado por USB (depuración USB activada), `flutter run` instala directo.

## Estructura

- `lib/main.dart` — arranque y tema (botones grandes, alto contraste)
- `lib/db.dart` — base de datos SQLite local
- `lib/models.dart` — máquinas, juegos, cuchillas, revisiones
- `lib/screens/juegos_screen.dart` — P1 lista de juegos
- `lib/screens/juego_screen.dart` — P1 detalle: 4 cuchillas
- `lib/screens/camera_screen.dart` — P2 cámara con guía fantasma
- `lib/screens/registro_screen.dart` — P3 registro (fecha, máquina, llapada, material)
- `lib/screens/comparacion_screen.dart` — P4 comparación con superposición
- `lib/screens/maquinas_screen.dart` — gestión de máquinas

## Permisos

Solo cámara (lo agrega automáticamente el plugin). Sin internet, sin cuentas, sin suscripciones.
