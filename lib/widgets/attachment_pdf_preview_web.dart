import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class AttachmentPdfPreview extends StatefulWidget {
  const AttachmentPdfPreview({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'application/pdf',
    super.key,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  @override
  State<AttachmentPdfPreview> createState() => _AttachmentPdfPreviewState();
}

class _AttachmentPdfPreviewState extends State<AttachmentPdfPreview> {
  String? _objectUrl;

  void _configureFrame(Object element) {
    final frame = element as html.IFrameElement;
    _objectUrl = html.Url.createObjectUrlFromBlob(
      html.Blob([widget.bytes], widget.mimeType),
    );
    frame
      ..src = _objectUrl
      ..title = widget.fileName
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
  }

  @override
  void dispose() {
    final url = _objectUrl;
    if (url != null) html.Url.revokeObjectUrl(url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: _configureFrame,
      );
}
