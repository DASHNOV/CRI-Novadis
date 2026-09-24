import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:signature/signature.dart';
import 'package:novadis_cri/core/utils/file_utils.dart';

final _fileUtils = createFileUtils();

/// Widget pour capturer une signature.
/// Si [savedSignatureBase64] est fourni, affiche un bouton pour l'utiliser directement.
class SignaturePadWidget extends StatefulWidget {
  final String label;
  final String? initialSignaturePath;
  final ValueChanged<String?> onSignatureSaved;
  final bool enabled;
  final Color penColor;
  final double penStrokeWidth;
  final String? savedSignatureBase64;

  /// Contenu (Markdown) affiché en lecture seule dans la popup de signature,
  /// p.ex. le « Travail effectué » que le client valide avant de signer.
  final String? contextMarkdown;

  /// Titre de l'encart contextuel affiché au-dessus de la zone de signature.
  final String contextTitle;

  const SignaturePadWidget({
    super.key,
    required this.label,
    this.initialSignaturePath,
    required this.onSignatureSaved,
    this.enabled = true,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.savedSignatureBase64,
    this.contextMarkdown,
    this.contextTitle = 'Travail effectué',
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late SignatureController _controller;
  String? _savedPath;
  bool _isSaving = false;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _savedPath = widget.initialSignaturePath;
    _hasSignature = _savedPath != null && _savedPath!.isNotEmpty;

    _controller = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor: Colors.white,
      onDrawStart: () {
        setState(() {
          _hasSignature = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _clearSignature() async {
    _controller.clear();
    setState(() {
      _savedPath = null;
      _hasSignature = false;
    });
    widget.onSignatureSaved(null);
  }

  Future<void> _useSavedSignature() async {
    final base64 = widget.savedSignatureBase64;
    if (base64 == null || base64.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final bytes = base64Decode(base64);
      final fileName = 'saved_sig_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = await _fileUtils.saveSignature(bytes, fileName);
      setState(() {
        _savedPath = filePath;
        _hasSignature = true;
      });
      widget.onSignatureSaved(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature enregistrée utilisée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la signature : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de sauvegarder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Uint8List? signature = await _controller.toPngBytes();

      if (signature == null) {
        throw Exception('Impossible de générer l\'image de signature');
      }

      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = await _fileUtils.saveSignature(signature, fileName);

      setState(() {
        _savedPath = filePath;
      });

      widget.onSignatureSaved(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        label: widget.label,
        controller: _controller,
        contextMarkdown: widget.contextMarkdown,
        contextTitle: widget.contextTitle,
        onClear: () {
          _controller.clear();
        },
        onSave: () async {
          Navigator.pop(context);
          await _saveSignature();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.enabled && _hasSignature)
              TextButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Effacer'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        if (widget.enabled &&
            !_hasSignature &&
            widget.savedSignatureBase64 != null &&
            widget.savedSignatureBase64!.isNotEmpty) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _useSavedSignature,
            icon: const Icon(Icons.draw, size: 16),
            label: const Text('Utiliser ma signature enregistrée'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('ou', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.enabled ? _showSignatureDialog : null,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasSignature
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: _hasSignature ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _savedPath != null && _savedPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb 
                      ? const Center(child: Text('Signature enregistrée (Web)'))
                      : _fileUtils.getFileWidget(_savedPath!),
                  )
                : _buildPlaceholder(theme),
          ),
        ),
        if (_isSaving)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enregistrement...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.draw_outlined, size: 32, color: theme.colorScheme.outline),
        const SizedBox(height: 8),
        Text(
          widget.enabled ? 'Appuyer pour signer' : 'Aucune signature',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Dialog de signature plein écran
class _SignatureDialog extends StatelessWidget {
  final String label;
  final SignatureController controller;
  final String? contextMarkdown;
  final String contextTitle;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _SignatureDialog({
    required this.label,
    required this.controller,
    this.contextMarkdown,
    this.contextTitle = 'Travail effectué',
    required this.onClear,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final hasContext =
        contextMarkdown != null && contextMarkdown!.trim().isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),

            // Rappel du travail effectué (lecture seule) avant signature
            if (hasContext) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  contextTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: size.height * 0.25),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  child: MarkdownBody(data: contextMarkdown!),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Zone de signature
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Indication
            Text(
              'Dessinez votre signature ci-dessus',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Effacer'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour prévisualiser une signature existante
class SignaturePreview extends StatelessWidget {
  final String? signaturePath;
  final String label;
  final double height;

  const SignaturePreview({
    super.key,
    this.signaturePath,
    required this.label,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSignature = signaturePath != null && signaturePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: hasSignature
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: kIsWeb
                    ? const Center(child: Text('Signé'))
                    : _fileUtils.getFileWidget(signaturePath!),
                )
              : Center(
                  child: Text(
                    'Non signé',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}




