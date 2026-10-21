import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vanity_provider.dart';
import '../../services/ocr/receipt_ocr_service.dart';
import '../../services/receipt_parser_service.dart';
import '../../theme/app_theme.dart';
import 'receipt_history_screen.dart';
import 'receipt_review_screen.dart';

/// An image chosen by the user. On web there is no filesystem [path]; [bytes] are
/// always kept so OCR can run on every platform.
class PickedReceiptImage {
  final Uint8List bytes;
  final String? path;
  final String? name;
  final String mimeType;

  const PickedReceiptImage({required this.bytes, this.path, this.name, this.mimeType = 'image/jpeg'});
}

typedef ReceiptImagePicker = Future<PickedReceiptImage?> Function();
typedef ReceiptTextRecognizer = Future<String> Function({String? imagePath, Uint8List? imageBytes, String? mimeType});

/// Default picker: file_picker on every platform, reading bytes so web works without a path.
Future<PickedReceiptImage?> pickReceiptImageWithFilePicker() async {
  final files = await FilePicker.pickFiles(dialogTitle: 'Select Receipt Image', type: FileType.image);
  if (files.isEmpty) return null; // user cancelled

  final picked = files.first;
  final bytes = await picked.readAsBytes();
  return PickedReceiptImage(
    bytes: bytes,
    path: kIsWeb ? null : picked.path,
    name: picked.name,
    mimeType: ReceiptOcrService.mimeTypeForExtension(picked.extension),
  );
}

class ReceiptScannerScreen extends StatefulWidget {
  /// Injectable for tests; defaults to [pickReceiptImageWithFilePicker].
  final ReceiptImagePicker? pickImage;

  /// Injectable for tests; defaults to [ReceiptParserService.extractText].
  final ReceiptTextRecognizer? recognizeText;

  const ReceiptScannerScreen({super.key, this.pickImage, this.recognizeText});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;
  PickedReceiptImage? _lastImage;
  final TextEditingController _manualTextController = TextEditingController();
  bool _showManualInput = false;

  @override
  void dispose() {
    _manualTextController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    PickedReceiptImage? image;
    try {
      image = await (widget.pickImage ?? pickReceiptImageWithFilePicker)();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not open the selected file: ${_clean(e)}';
        _showManualInput = true;
      });
      return;
    }
    if (image == null) return; // cancelled: nothing to do

    if (image.bytes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'The selected image file is empty or could not be read.';
        _showManualInput = true;
      });
      return;
    }

    _lastImage = image;
    await _runOcr(image);
  }

  Future<void> _runOcr(PickedReceiptImage image) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = kIsWeb
          ? 'Reading receipt in your browser (first scan loads the OCR engine, ~10 MB)...'
          : 'Reading receipt using on-device OCR...';
    });

    try {
      final recognize = widget.recognizeText ?? ReceiptParserService.extractText;
      final rawText = await recognize(imagePath: image.path, imageBytes: image.bytes, mimeType: image.mimeType);

      if (!mounted) return;

      if (rawText.trim().isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
          _errorMessage =
              'No text was recognized in this image. Try a sharper, well-lit photo, '
              'or type the receipt details below.';
          _showManualInput = true;
        });
        return;
      }

      _parseAndNavigate(rawText);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
        _errorMessage = 'Could not scan the image: ${_clean(e)}';
        _showManualInput = true;
      });
    }
  }

  static String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  void _parseAndNavigate(String text) {
    setState(() {
      _isProcessing = false;
      _statusMessage = null;
      _errorMessage = null;
    });

    final defaultCurrency = context.read<VanityProvider>().currencySymbol;
    final draft = ReceiptParserService.parseReceiptText(text, defaultCurrency: defaultCurrency);

    // Nothing is saved here: the review screen saves only after the user confirms.
    Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ReceiptReviewScreen(initialDraft: draft))).then((
      saved,
    ) {
      if (saved == true && mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          TextButton.icon(
            key: const Key('open-receipt-history'),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceiptHistoryScreen())),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Receipt History'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1ECE8)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRose.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 40, color: AppTheme.primaryRose),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'On-Device Receipt Scanning',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan or upload a paper receipt or e-receipt screenshot. Your image is processed on this device (or in your browser) without cloud uploads.\n\nYou will be able to review, edit line items, and match purchases to your vanity items before saving.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1ECE8)),
                ),
                child: Column(
                  children: [
                    if (_lastImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _lastImage!.bytes,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const CircularProgressIndicator(color: AppTheme.primaryRose),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage ?? 'Processing...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              if (_errorMessage != null) ...[
                Container(
                  key: const Key('receipt-scan-error'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.statusAmberBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusAmber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.statusAmber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                          ),
                        ],
                      ),
                      if (_lastImage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _runOcr(_lastImage!),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry scan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _pickReceiptImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_lastImage == null ? 'Select Receipt Image' : 'Select Another Image'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showManualInput = !_showManualInput;
                  });
                },
                icon: Icon(_showManualInput ? Icons.keyboard_hide : Icons.edit_note_rounded),
                label: Text(_showManualInput ? 'Hide Manual Input' : 'Paste Receipt Text Manually'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],

            if (_showManualInput && !_isProcessing) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1ECE8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Paste Receipt Text',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('receipt-manual-text'),
                      controller: _manualTextController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText:
                            'SEPHORA\n2026-10-12\nHyaluronic Acid Serum \$24.00\nSubtotal \$24.00\nTax \$1.92\nTotal \$25.92',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final text = _manualTextController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Please enter or paste receipt text')));
                          return;
                        }
                        _parseAndNavigate(text);
                      },
                      child: const Text('Parse Text'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
