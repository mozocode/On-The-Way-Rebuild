import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../data/vehicle_data_loader.dart';
import '../../widgets/common/step_progress_indicator.dart';
import 'location_screen.dart';

class VehicleInfoScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;

  const VehicleInfoScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
  });

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  String? _selectedYear;
  String? _selectedMake;
  String? _selectedModel;
  String? _selectedColor;
  XFile? _vehicleImage;
  bool _dataLoaded = false;
  String? _loadError;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    try {
      await VehicleDataLoader.ensureLoaded();
      if (mounted) setState(() => _dataLoaded = true);
    } catch (e) {
      if (mounted) setState(() {
        _loadError = e.toString();
        _dataLoaded = true;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _vehicleImage = picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera not available: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _vehicleImage = picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: $e')),
        );
      }
    }
  }

  List<String> get _years => VehicleDataLoader.years;
  List<String> get _availableMakes => VehicleDataLoader.makeNames;
  List<String> get _availableModels => VehicleDataLoader.modelsForMake(_selectedMake ?? '');
  List<String> get _colors => VehicleDataLoader.colors;

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load vehicle data: $_loadError', textAlign: TextAlign.center))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                      Expanded(
                        child: Text(
                          widget.serviceLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StepProgressIndicator(currentStep: 1),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Year – scrollable list (47 options)
                    _buildScrollableSelectField(
                      label: 'Year',
                      value: _selectedYear,
                      hint: 'Select year',
                      items: _years,
                      onChanged: (v) => setState(() {
                        _selectedYear = v;
                        _selectedMake = null;
                        _selectedModel = null;
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Make – scrollable list so all makes are accessible
                    _buildScrollableSelectField(
                      label: 'Make',
                      value: _selectedMake,
                      hint: 'Select make',
                      items: _selectedYear != null ? _availableMakes : [],
                      onChanged: (v) => setState(() {
                        _selectedMake = v;
                        _selectedModel = null;
                      }),
                      enabled: _selectedYear != null,
                    ),
                    if (_selectedYear == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Select year first',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Model – scrollable list so all models are accessible
                    _buildScrollableSelectField(
                      label: 'Model',
                      value: _selectedModel,
                      hint: 'Select model',
                      items: _availableModels,
                      onChanged: (v) => setState(() => _selectedModel = v),
                      enabled: _selectedMake != null,
                    ),
                    if (_selectedMake == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Select make first',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Color – scrollable list (68 options)
                    _buildScrollableSelectField(
                      label: 'Color',
                      value: _selectedColor,
                      hint: 'Select color',
                      items: _colors,
                      onChanged: (v) => setState(() => _selectedColor = v),
                    ),

                    const SizedBox(height: 24),

                    // Photo
                    _fieldLabel('Photo', required: true),
                    const SizedBox(height: 4),
                    Text(
                      'Please take a clear photo of your vehicle',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _photoOption(
                          icon: Icons.camera_alt,
                          label: 'Take Photo',
                          isSelected: _vehicleImage != null,
                          onTap: _pickImageFromCamera,
                        ),
                        const SizedBox(width: 16),
                        _photoOption(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          isSelected: _vehicleImage != null,
                          onTap: _pickImageFromGallery,
                        ),
                      ],
                    ),
                    if (_vehicleImage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Photo added',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canContinue ? _onContinue : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canContinue =>
      _selectedYear != null &&
      _selectedMake != null &&
      _selectedModel != null &&
      _selectedColor != null;

  void _onContinue() {
    final vehicleInfo =
        '$_selectedYear $_selectedMake $_selectedModel ($_selectedColor)';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          serviceType: widget.serviceType,
          serviceLabel: widget.serviceLabel,
          vehicleInfo: vehicleInfo,
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        children: required
            ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
            : [],
      ),
    );
  }

  static const double _dropdownMenuMaxHeight = 320;

  Widget _buildDropdown({
    String? value,
    required String hint,
    required List<String> items,
    void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          menuMaxHeight: _dropdownMenuMaxHeight,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Opens a full-screen scrollable list so all options are accessible (used for Make & Model).
  Widget _buildScrollableSelectField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required: true),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled && items.isNotEmpty
              ? () => _showScrollablePicker(
                    title: label,
                    items: items,
                    selected: value,
                    onSelect: (v) {
                      Navigator.pop(context);
                      onChanged(v);
                    },
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showScrollablePicker({
    required String title,
    required List<String> items,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final isSelected = item == selected;
                      return ListTile(
                        title: Text(item),
                        trailing: isSelected ? Icon(Icons.check, color: AppTheme.brandGreen) : null,
                        onTap: () => onSelect(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppTheme.brandGreen : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.brandGreen : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
