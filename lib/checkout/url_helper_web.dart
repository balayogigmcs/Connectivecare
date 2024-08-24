import 'dart:html' as html;

String getCurrentUrl() {
  print("get url for web");
  return html.window.location.href.split('#')[0];
}
