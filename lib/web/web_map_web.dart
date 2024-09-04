import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:js/js_util.dart' as js_util;

class WebMap extends StatefulWidget {
  final LatLng initialPosition;
  final double zoom;
  final List<MapMarker> markers;

  const WebMap({
    Key? key,
    required this.initialPosition,
    this.zoom = 12,
    this.markers = const [],
  }) : super(key: key);

  @override
  _WebMapState createState() => _WebMapState();
}

class _WebMapState extends State<WebMap> {
  late html.DivElement _mapDiv;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _mapDiv = html.DivElement()
        ..id = 'map-canvas'
        ..style.width = '100%'
        ..style.height = '100%';

      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'google-map-view',
        (int viewId) => _mapDiv,
      );

      html.window.onLoad.listen((event) {
        final mapOptions = js_util.jsify({
          'center': js_util.jsify({
            'lat': widget.initialPosition.latitude,
            'lng': widget.initialPosition.longitude,
          }),
          'zoom': widget.zoom,
        });

        final map = js_util.callMethod(
          html.window,
          'google.maps.Map',
          [_mapDiv, mapOptions],
        );

        // Add markers
        for (var marker in widget.markers) {
          final markerOptions = js_util.jsify({
            'position': js_util.jsify({
              'lat': marker.position.latitude,
              'lng': marker.position.longitude,
            }),
            'map': map,
            'title': marker.title,
            if (marker.iconUrl != null) 'icon': marker.iconUrl,
          });

          js_util.callMethod(
            html.window,
            'google.maps.Marker',
            [markerOptions],
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: 'google-map-view');
    } else {
      return const Center(
        child: Text('Google Maps is not supported on this platform'),
      );
    }
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class MapMarker {
  final LatLng position;
  final String title;
  final String? iconUrl;

  MapMarker({
    required this.position,
    required this.title,
    this.iconUrl,
  });
}
