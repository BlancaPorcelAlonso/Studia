import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme/cottagecore_theme.dart';
import 'attachment_pdf_preview.dart';

class AttachmentPreviewDialog extends StatefulWidget {
  const AttachmentPreviewDialog({
    required this.fileName,
    required this.loadBytes,
    super.key,
  });

  final String fileName;
  final Future<Uint8List> Function() loadBytes;

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required Future<Uint8List> Function() loadBytes,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => AttachmentPreviewDialog(
          fileName: fileName,
          loadBytes: loadBytes,
        ),
      );

  @override
  State<AttachmentPreviewDialog> createState() =>
      _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog> {
  late final Future<Uint8List> _bytesFuture = widget.loadBytes();

  String get _extension => widget.fileName.split('.').last.toLowerCase().trim();

  bool get _isImage =>
      const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(_extension);

  bool get _isText => const {
        'txt',
        'md',
        'csv',
        'json',
        'xml',
        'log',
        'yaml',
        'yml',
      }.contains(_extension);

  bool get _isMedia => const {
        'mp3',
        'wav',
        'ogg',
        'mp4',
        'webm',
        'mov',
      }.contains(_extension);

  String get _mimeType => switch (_extension) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'ogg' => 'audio/ogg',
        'mp4' => 'video/mp4',
        'webm' => 'video/webm',
        'mov' => 'video/quicktime',
        'txt' || 'log' => 'text/plain',
        'md' => 'text/markdown',
        'csv' => 'text/csv',
        'json' => 'application/json',
        'xml' => 'application/xml',
        'yaml' || 'yml' => 'text/yaml',
        _ => 'application/octet-stream',
      };

  IconData get _fileIcon => switch (_extension) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => Icons.image_outlined,
        'txt' ||
        'md' ||
        'csv' ||
        'json' ||
        'xml' ||
        'log' ||
        'yaml' ||
        'yml' =>
          Icons.description_outlined,
        _ => Icons.attach_file_rounded,
      };

  Future<void> _download(Uint8List bytes) async {
    try {
      await FilePicker.saveFile(fileName: widget.fileName, bytes: bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo descargar este archivo.')),
      );
    }
  }

  Widget _preview(Uint8List bytes) {
    if (_extension == 'pdf') {
      return AttachmentPdfPreview(bytes: bytes, fileName: widget.fileName);
    }
    if (_isImage) {
      return InteractiveViewer(
        minScale: 0.7,
        maxScale: 6,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
    if (_isText) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          utf8.decode(bytes, allowMalformed: true),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      );
    }
    if (_isMedia) {
      return AttachmentPdfPreview(
        bytes: bytes,
        fileName: widget.fileName,
        mimeType: _mimeType,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_off_outlined,
                size: 36, color: CottagecoreColors.warmBrown),
            const SizedBox(height: 12),
            const Text(
              'Este formato no se puede previsualizar en el navegador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _download(bytes),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar archivo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: CottagecoreColors.creamCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: screen.width > 960 ? 920 : screen.width - 24,
        height: screen.height - 48,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(_fileIcon, color: CottagecoreColors.forest),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FutureBuilder<Uint8List>(
                    future: _bytesFuture,
                    builder: (context, snapshot) => IconButton(
                      tooltip: 'Descargar archivo',
                      onPressed: snapshot.hasData
                          ? () => _download(snapshot.data!)
                          : null,
                      icon: const Icon(Icons.download_outlined),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar vista previa',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _bytesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No se pudo cargar el archivo. Comprueba tu conexión e inténtalo de nuevo.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (_extension == 'pdf' || _isImage || _isText || _isMedia) {
                    return _preview(snapshot.data!);
                  }
                  return _preview(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
