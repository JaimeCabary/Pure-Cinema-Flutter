// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = {};

Widget buildWebYouTubePlayer(String trailerKey) {
  final viewType = 'youtube-trailer-$trailerKey';
  
  if (!_registeredViews.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = 'https://www.youtube.com/embed/$trailerKey?autoplay=1&mute=1&controls=1&playsinline=1&rel=0&modestbranding=1&loop=1&playlist=$trailerKey'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return iframe;
    });
    _registeredViews.add(viewType);
  }

  return HtmlElementView(viewType: viewType);
}
