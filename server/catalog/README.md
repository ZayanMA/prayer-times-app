# Static Catalog Feed

The app reads mosque metadata and daily timetable data from this static feed.
Host the `server/catalog` directory at the configured `CATALOG_BASE_URL`.

For local development:

```sh
python3 -m http.server 8080 --directory server
flutter run -d linux --dart-define=CATALOG_BASE_URL=http://localhost:8080/catalog/v1/
```

The source URLs used for scraping live in `server/source_config/mosques.json`.
They are intentionally not part of the app runtime database seed.

Refresh the feed with the daily catalog job:

```sh
dart run prayer_times_catalog_job:generate_catalog .
```

Schedule that command before UK Fajr on the host that publishes the static feed.
