# Prayer Times App Shell

This directory contains the Flutter app code. Platform runner folders are generated
by Flutter tooling and are intentionally not hand-written here.

After installing Flutter, generate the MVP runners from this directory:

```sh
flutter create --platforms=linux,android --project-name prayer_times_app .
```

Then run:

```sh
flutter pub get
cd ../../packages/data
dart run build_runner build --delete-conflicting-outputs
cd ../../apps/app
flutter run -d linux
```

For local catalog data, serve the static feed from the repository root:

```sh
python3 -m http.server 8080 --directory server
flutter run -d linux --dart-define=CATALOG_BASE_URL=http://localhost:8080/catalog/v1/
```
