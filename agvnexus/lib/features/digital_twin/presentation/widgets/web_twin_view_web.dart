// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Web implementation of WebTwinView hosting the Three.js digital-twin viewer
/// inside a sandboxed IFrameElement with bidirectional postMessage support.
class WebTwinView extends StatefulWidget {
  final String robotId;
  final String? token;
  final VoidCallback? onSwitchTo2D;

  const WebTwinView({
    super.key,
    required this.robotId,
    this.token,
    this.onSwitchTo2D,
  });

  @override
  State<WebTwinView> createState() => _WebTwinViewState();
}

class _WebTwinViewState extends State<WebTwinView> {
  late final String _viewId;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewId = 'threejs-twin-${widget.robotId}-${DateTime.now().millisecondsSinceEpoch}';
    final tokenParam = widget.token != null ? '&token=${widget.token}' : '';
    final src = '/viewer/index.html?robot_id=${widget.robotId}$tokenParam';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen';
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant WebTwinView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.robotId != widget.robotId && _iframe != null) {
      _iframe?.contentWindow?.postMessage(
        {'action': 'setRobot', 'robotId': widget.robotId},
        '*',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
