import 'dart:html' as html;

String getCurrentUrl() {
  return html.window.location.href.split('#')[0];
}
