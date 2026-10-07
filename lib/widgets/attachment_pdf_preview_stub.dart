import 'dart:typed_data';

import 'package:flutter/material.dart';

class AttachmentPdfPreview extends StatelessWidget {
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
  Widget build(BuildContext context) => const Center(
        child: Text('La vista previa integrada está disponible en navegador.'),
      );
}
