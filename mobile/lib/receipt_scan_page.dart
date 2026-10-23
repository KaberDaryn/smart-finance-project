import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'receipt_image.dart';

typedef ReceiptPhotoPicker = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickReceiptPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source);
  if (file == null) return null;
  if (await file.length() > 20 * 1024 * 1024) {
    throw const FormatException('Choose a photo smaller than 20 MiB.');
  }
  return file.readAsBytes();
}

class ReceiptScanPage extends StatefulWidget {
  const ReceiptScanPage({super.key, required this.api, this.pickPhoto});
  final FinanceApi api;
  final ReceiptPhotoPicker? pickPhoto;

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  bool consent = false;
  bool busy = false;
  String? error;

  Future<void> scan(ImageSource source) async {
    if (busy || !consent) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await (widget.pickPhoto ?? pickReceiptPhoto)(source);
      if (bytes == null || !mounted) return;
      final photo = await compute(compressReceiptPhoto, bytes);
      if (!mounted) return;
      final receipt = await widget.api.parseReceipt(photo);
      if (mounted) Navigator.pop(context, receipt);
    } catch (failure) {
      if (mounted) {
        setState(() {
          error = failure is ApiFailure
              ? failure.message
              : failure is FormatException
              ? failure.message
              : 'Could not read this photo. Try again or enter the expense manually.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan receipt')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Choose a clear photo of the whole receipt. The photo is sent to an external service for recognition. You can review and edit every field before saving.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I agree to send this photo for recognition.'),
              value: consent,
              onChanged: busy
                  ? null
                  : (value) => setState(() => consent = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy || !consent
                  ? null
                  : () => scan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take a photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy || !consent
                  ? null
                  : () => scan(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
            ),
            if (busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: const Text('Reading receipt...'),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Enter expense manually'),
            ),
          ],
        ),
      ),
    ),
  );
}
