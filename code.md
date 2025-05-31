```dart
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
      - uses: subosito/flutter-action@v2
      - name: Build APK Release
        run: flutter build apk --release
      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_ANDROID_APP_ID }}
          token: ${{ secrets.FIREBASE_TOKEN }}
          groups: beta-testers
          file: build/app/outputs/flutter-apk/app-release.apk
name: Android Release
on:
  push:
    tags: ['v*']

jobs:
  build:



```
