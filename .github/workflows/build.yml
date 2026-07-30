name: Compilar APK

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Generar proyecto Android
        run: flutter create . --platforms android --project-name cuchillas

      - name: Dependencias
        run: flutter pub get

      - name: Compilar APK
        run: flutter build apk --release

      - name: Publicar APK
        uses: actions/upload-artifact@v4
        with:
          name: cuchillas-apk
          path: build/app/outputs/flutter-apk/app-release.apk
