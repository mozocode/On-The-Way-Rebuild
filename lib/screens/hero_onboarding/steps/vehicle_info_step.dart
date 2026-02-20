import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hero_application_model.dart';
import '../../../providers/hero_application_provider.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';

class VehicleInfoStep extends ConsumerStatefulWidget {
  const VehicleInfoStep({super.key});

  @override
  ConsumerState<VehicleInfoStep> createState() => _VehicleInfoStepState();
}

class _VehicleInfoStepState extends ConsumerState<VehicleInfoStep>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  final _makeCtl = TextEditingController();
  final _modelCtl = TextEditingController();
  final _yearCtl = TextEditingController();
  final _colorCtl = TextEditingController();
  final _plateCtl = TextEditingController();
  final _vinCtl = TextEditingController();

  // Insurance
  final _insProviderCtl = TextEditingController();
  final _insPolicyCtl = TextEditingController();
  final _insExpCtl = TextEditingController();

  // Registration
  final _regExpCtl = TextEditingController();

  String _vehicleType = 'car';
  String? _plateState;
  String? _regState;
  bool _hasHitch = false;
  bool _hasTowPackage = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final info = ref.read(heroApplicationProvider).application?.vehicleInfo;
    if (info == null) return;

    _makeCtl.text = info.make;
    _modelCtl.text = info.model;
    _yearCtl.text = info.year.toString();
    _colorCtl.text = info.color;
    _plateCtl.text = info.licensePlate;
    _plateState = info.licensePlateState.isEmpty ? null : info.licensePlateState;
    _vinCtl.text = info.vin ?? '';
    _vehicleType = info.vehicleType;
    _hasHitch = info.hasHitch;
    _hasTowPackage = info.hasTowPackage;
    _insProviderCtl.text = info.insurance.provider;
    _insPolicyCtl.text = info.insurance.policyNumber;
    _insExpCtl.text = info.insurance.expirationDate;
    _regExpCtl.text = info.registration.expirationDate;
    _regState = info.registration.state.isEmpty ? null : info.registration.state;
  }

  @override
  void dispose() {
    for (final c in [
      _makeCtl, _modelCtl, _yearCtl, _colorCtl, _plateCtl, _vinCtl,
      _insProviderCtl, _insPolicyCtl, _insExpCtl, _regExpCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSaving = ref.watch(isApplicationSavingProvider);
    final error = ref.watch(applicationErrorProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Vehicle Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tell us about your vehicle',
              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 20),

          if (error != null) ...[
            _errorBanner(error),
            const SizedBox(height: 16),
          ],

          // Vehicle type
          const Text('Vehicle Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vehicleTypes.entries.map((e) {
              final selected = _vehicleType == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _vehicleType = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Make / Model / Year
          Row(children: [
            Expanded(
              child: CustomTextField(
                controller: _makeCtl,
                label: 'Make',
                hintText: 'Ford',
                validator: (v) => Validators.required(v, fieldName: 'Make'),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _modelCtl,
                label: 'Model',
                hintText: 'F-150',
                validator: (v) => Validators.required(v, fieldName: 'Model'),
                textInputAction: TextInputAction.next,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: CustomTextField(
                controller: _yearCtl,
                label: 'Year',
                hintText: '2022',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.length != 4) return 'Enter year';
                  final year = int.tryParse(v);
                  if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                    return 'Invalid year';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _colorCtl,
                label: 'Color',
                hintText: 'White',
                validator: (v) => Validators.required(v, fieldName: 'Color'),
                textInputAction: TextInputAction.next,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // License plate
          Row(children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _plateCtl,
                label: 'License Plate',
                hintText: 'ABC 1234',
                validator: Validators.licensePlate,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _stateDropdown('State', _plateState, (v) =>
                setState(() => _plateState = v))),
          ]),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _vinCtl,
            label: 'VIN (Optional)',
            hintText: '17-character VIN',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Capabilities
          SwitchListTile(
            title: const Text('Has Tow Hitch'),
            value: _hasHitch,
            onChanged: (v) => setState(() => _hasHitch = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Has Tow Package'),
            value: _hasTowPackage,
            onChanged: (v) => setState(() => _hasTowPackage = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Insurance
          const Text('Insurance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _insProviderCtl,
            label: 'Insurance Provider',
            hintText: 'State Farm',
            validator: (v) => Validators.required(v, fieldName: 'Provider'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _insPolicyCtl,
            label: 'Policy Number',
            hintText: 'POL-123456',
            validator: (v) => Validators.required(v, fieldName: 'Policy number'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _insExpCtl,
            label: 'Insurance Expiration',
            hintText: 'MM/DD/YYYY',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _pickExpDate(_insExpCtl),
            validator: (v) => Validators.required(v, fieldName: 'Expiration date'),
          ),
          const SizedBox(height: 22),

          // Registration
          const Text('Vehicle Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _regExpCtl,
                label: 'Registration Expiration',
                hintText: 'MM/DD/YYYY',
                prefixIcon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _pickExpDate(_regExpCtl),
                validator: (v) => Validators.required(v, fieldName: 'Expiration'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _stateDropdown('State', _regState, (v) =>
                setState(() => _regState = v))),
          ]),
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
                onPressed: isSaving ? null : _save,
                isLoading: isSaving,
                child: const Text('Continue'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _stateDropdown(String label, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: _usStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }

  Future<void> _pickExpDate(TextEditingController ctl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      ctl.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Widget _errorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final info = VehicleInfo(
      make: _makeCtl.text.trim(),
      model: _modelCtl.text.trim(),
      year: int.parse(_yearCtl.text.trim()),
      color: _colorCtl.text.trim(),
      licensePlate: _plateCtl.text.trim(),
      licensePlateState: _plateState ?? '',
      vin: _vinCtl.text.trim().isEmpty ? null : _vinCtl.text.trim(),
      vehicleType: _vehicleType,
      hasHitch: _hasHitch,
      hasTowPackage: _hasTowPackage,
      insurance: InsuranceInfo(
        provider: _insProviderCtl.text.trim(),
        policyNumber: _insPolicyCtl.text.trim(),
        expirationDate: _insExpCtl.text.trim(),
      ),
      registration: RegistrationInfo(
        expirationDate: _regExpCtl.text.trim(),
        state: _regState ?? '',
      ),
    );

    await ref.read(heroApplicationProvider.notifier).saveVehicleInfo(info);
  }

  static const _vehicleTypes = {
    'car': 'Car',
    'truck': 'Truck',
    'suv': 'SUV',
    'van': 'Van',
    'flatbed': 'Flatbed',
    'tow_truck': 'Tow Truck',
  };

  static const _usStates = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
  ];
}
