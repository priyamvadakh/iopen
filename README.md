# Remote Guide

Flutter app where travellers pay a local Guide to inspect a place, car,
property or hotel through live video before spending time or money.

Live demo: https://priyamvadakh.github.io/remote-guide/

This is a front-end prototype. Content is sample data in
`lib/data/content.dart`, and payment is not connected.

## Screens

- **Home**: wallet chip, intent chips, interactive globe with Guide pins,
  trust strip, recent sessions, popular cities.
- **City zoom**: tapping a city (e.g. Dubai) flies the globe into a stylised
  skyline with an intent picker.
- **Place view**: drag-to-explore panorama with hotspots, 15-sec sample,
  check picker, nearby Guides, pricing and a sticky request bar.
- **Explore by Country**, **Car / Hotel / Property / Place** detail pages,
  **Sessions**, **Map**, **Wallet**, **Profile**.

## Layout

```
lib/
  main.dart             app entry; Firebase is optional until configured
  app/                  theme, router, phone frame for desktop browsers
  data/                 sample content and globe land dots
  widgets/              globe, skyline, buttons and shared UI
  screens/              one file per screen (tab screens grouped)
assets/images/          photos (see CREDITS.md)
```

## Run locally

```sh
flutter build web --release
python3 -m http.server 8080 --directory build/web
# open http://localhost:8080
```

For editing with hot reload: `flutter run -d web-server --web-port 8080`.

## Deploy

Every push to `main` runs `.github/workflows/pages.yml`, which tests, builds
and publishes the site to GitHub Pages.

## Firebase

Firebase packages are installed but not configured. To connect a project, run
`flutterfire configure`; the app initialises Firebase automatically once
`lib/firebase_options.dart` is generated.

## Vercel

Live: https://remote-guide-eight.vercel.app

Vercel serves the prebuilt web app. To redeploy after changes:

```sh
flutter build web --release
npx vercel deploy build/web --prod --yes --project remote-guide
```
