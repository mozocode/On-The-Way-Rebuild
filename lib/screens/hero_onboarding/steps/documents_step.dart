import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import '../../../models/hero_application_model.dart';
import '../../../providers/hero_application_provider.dart';
import '../../../widgets/common/custom_button.dart';

class DocumentsStep extends ConsumerStatefulWidget {
  const DocumentsStep({super.key});

  @override
  ConsumerState<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends ConsumerState<DocumentsStep>
    with AutomaticKeepAliveClientMixin {
  final _imagePicker = ImagePicker();

  static const _requiredDocs = [
    _DocReq(DocumentType.driversLicenseFront, "Driver's License (Front)",
        'Clear photo of the front of your license', Icons.badge, true),
    _DocReq(DocumentType.driversLicenseBack, "Driver's License (Back)",
        'Clear photo of the back of your license', Icons.badge, true),
    _DocReq(DocumentType.insuranceCard, 'Insurance Card',
        'Current auto insurance card', Icons.security, true),
    _DocReq(DocumentType.vehicleRegistration, 'Vehicle Registration',
        'Current vehicle registration', Icons.description, true),
    _DocReq(DocumentType.profilePhoto, 'Profile Photo',
        'Clear headshot for your hero profile', Icons.person, true),
  ];

  static const _optionalDocs = [
    _DocReq(DocumentType.vehiclePhotoFront, 'Vehicle Photo (Front)',
        'Photo of vehicle from the front', Icons.directions_car, false),
    _DocReq(DocumentType.vehiclePhotoSide, 'Vehicle Photo (Side)',
        'Photo of vehicle from the side', Icons.directions_car, false),
    _DocReq(DocumentType.certification, 'Certifications',
        'Any relevant certifications', Icons.workspace_premium, false),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appState = ref.watch(heroApplicationProvider);
    final docs = appState.application?.documents ?? [];
    final isSaving = appState.isSaving;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Upload Documents',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Verify your identity and vehicle',
            style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        const SizedBox(height: 20),

        // Required
        const Text('Required Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._requiredDocs.map((req) => _DocCard(
              req: req,
              uploaded: _findDoc(docs, req.type),
              isUploading: isSaving,
              onUpload: () => _pick(req.type),
              onDelete: (d) => _delete(d),
            )),

        const SizedBox(height: 20),

        // Optional
        const Text('Optional Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._optionalDocs.map((req) => _DocCard(
              req: req,
              uploaded: _findDoc(docs, req.type),
              isUploading: isSaving,
              onUpload: () => _pick(req.type),
              onDelete: (d) => _delete(d),
            )),

        const SizedBox(height: 28),

        // Navigation
        Row(children: [
          Expanded(
            child: CustomButton(
              variant: ButtonVariant.outlined,
              onPressed: () =>
                  ref.read(heroApplicationProvider.notifier).previousStep(),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              onPressed: _canContinue(docs) && !isSaving ? _continue : null,
              isLoading: isSaving,
              child: const Text('Continue'),
            ),
          ),
        ]),

        if (!_canContinue(docs)) ...[
          const SizedBox(height: 8),
          Text('Upload all required documents to continue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  UploadedDocument? _findDoc(List<UploadedDocument> docs, DocumentType type) {
    for (final d in docs) {
      if (d.type == type) return d;
    }
    return null;
  }

  bool _canContinue(List<UploadedDocument> docs) {
    return _requiredDocs.every((r) => _findDoc(docs, r.type) != null);
  }

  Future<void> _pick(DocumentType type) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Upload PDF'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    File? file;

    if (source == 'camera' || source == 'gallery') {
      final image = await _imagePicker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) file = File(image.path);
    } else if (source == 'file') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result?.files.single.path != null) {
        file = File(result!.files.single.path!);
      }
    }

    if (file != null) {
      await ref.read(heroApplicationProvider.notifier).uploadDocument(type, file);
    }
  }

  Future<void> _delete(UploadedDocument document) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This will remove the uploaded file.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(heroApplicationProvider.notifier).deleteDocument(document);
    }
  }

  Future<void> _continue() async {
    await ref.read(heroApplicationProvider.notifier).completeDocumentsStep();
  }
}

class _DocReq {
  final DocumentType type;
  final String title;
  final String description;
  final IconData icon;
  final bool required;
  const _DocReq(this.type, this.title, this.description, this.icon, this.required);
}

class _DocCard extends StatelessWidget {
  final _DocReq req;
  final UploadedDocument? uploaded;
  final bool isUploading;
  final VoidCallback onUpload;
  final ValueChanged<UploadedDocument> onDelete;

  const _DocCard({
    required this.req,
    required this.uploaded,
    required this.isUploading,
    required this.onUpload,
    required this.onDelete,
  });

  bool get _isImageUrl {
    if (uploaded == null) return false;
    final url = uploaded!.url.toLowerCase();
    return url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('image%2f');
  }

  @override
  Widget build(BuildContext context) {
    final done = uploaded != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (done && _isImageUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  uploaded!.url,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildIconBox(done),
                ),
              )
            else
              _buildIconBox(done),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(req.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    if (req.required)
                      Text(' *', style: TextStyle(color: Colors.red.shade400, fontSize: 14)),
                  ]),
                  const SizedBox(height: 2),
                  if (done)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Uploaded successfully',
                          style: TextStyle(
                            color: AppTheme.brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      req.description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (done)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: isUploading ? null : onUpload,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Replace'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => onDelete(uploaded!),
                  ),
                ],
              )
            else
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isUploading ? null : onUpload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Upload'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(bool done) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: done ? AppTheme.brandGreen.withAlpha(20) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        done ? Icons.check_circle : req.icon,
        color: done ? AppTheme.brandGreen : Colors.grey[500],
        size: 24,
      ),
    );
  }
}
