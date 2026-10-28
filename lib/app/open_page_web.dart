import 'package:web/web.dart' as web;

/// Opens another page of the web demo, e.g. `variations.html`.
void openDemoPage(String path) => web.window.location.href = path;

/// Whether [openDemoPage] can open anything here.
const canOpenDemoPages = true;
