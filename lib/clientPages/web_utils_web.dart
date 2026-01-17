// web_utils_web.dart
import 'dart:html' as html;

/// Opens the given URL in a new browser tab (Web only)
void openUrl(String url) {
  html.window.open(url, '_blank');
}
