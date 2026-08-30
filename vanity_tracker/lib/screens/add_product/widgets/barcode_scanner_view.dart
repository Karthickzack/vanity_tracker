import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerView extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;
  final VoidCallback onManualEntryRequested;

  const BarcodeScannerView({
    super.key,
    required this.onBarcodeScanned,
    required this.onManualEntryRequested,
  });

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _isScanned = true;
        widget.onBarcodeScanned(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Viewfinder
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Camera unavailable (Emulator / Permission)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onManualEntryRequested,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Enter Product Manually'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Scanning Target Frame Overlay
        Center(
          child: Container(
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 2,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top Controls: Torch & Camera Flip
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () {
                  _scannerController.toggleTorch();
                  setState(() => _torchOn = !_torchOn);
                },
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => _scannerController.switchCamera(),
              ),
            ],
          ),
        ),

        // Bottom instruction banner & manual fallback button
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Point camera at product barcode to auto-fill',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onManualEntryRequested,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Switch to Manual Entry'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide.none,
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
