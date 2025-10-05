import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class KnowledgeGraphWidget extends StatefulWidget {
  final String htmlContent;

  const KnowledgeGraphWidget({super.key, required this.htmlContent});

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget> {
  late final String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'knowledge-graph-${DateTime.now().millisecondsSinceEpoch}';

    final iframe = html.IFrameElement()
      ..width = '100%'
      ..height = '100%'
      ..style.border = 'none'
      ..srcdoc = widget.htmlContent;

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HtmlElementView(viewType: viewId),
    );
  }
}