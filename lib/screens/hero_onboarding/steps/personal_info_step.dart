import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hero_application_model.dart';
import '../../../providers/hero_application_provider.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';

class PersonalInfoStep extends ConsumerStatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  ConsumerState<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends ConsumerState<PersonalInfoStep>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _dobCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _streetCtl = TextEditingController();
  final _aptCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _zipCtl = TextEditingController();
  final _emergNameCtl = TextEditingController();
  final _emergRelCtl = TextEditingController();
  final _emergPhoneCtl = TextEditingController();
  final _ssnCtl = TextEditingController();

  String? _selectedState;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final info =
        ref.read(heroApplicationProvider).application?.personalInfo;
    if (info == null) return;

    _firstNameCtl.text = info.firstName;
    _lastNameCtl.text = info.lastName;
    _dobCtl.text = info.dateOfBirth;
    _emailCtl.text = info.email;
    _phoneCtl.text = info.phone;
    _streetCtl.text = info.address.street;
    _aptCtl.text = info.address.apartment ?? '';
    _cityCtl.text = info.address.city;
    _selectedState = info.address.state.isEmpty ? null : info.address.state;
    _zipCtl.text = info.address.zipCode;
    _emergNameCtl.text = info.emergencyContact.name;
    _emergRelCtl.text = info.emergencyContact.relationship;
    _emergPhoneCtl.text = info.emergencyContact.phone;
    _ssnCtl.text = info.ssnLastFour ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtl, _lastNameCtl, _dobCtl, _emailCtl, _phoneCtl,
      _streetCtl, _aptCtl, _cityCtl, _zipCtl,
      _emergNameCtl, _emergRelCtl, _emergPhoneCtl, _ssnCtl,
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
          const Text('Personal Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tell us about yourself',
              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 20),

          if (error != null) ...[
            _ErrorBanner(error: error, onDismiss: () =>
                ref.read(heroApplicationProvider.notifier).clearError()),
            const SizedBox(height: 16),
          ],

          // Name
          Row(children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameCtl,
                label: 'First Name',
                hintText: 'John',
                validator: Validators.name,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _lastNameCtl,
                label: 'Last Name',
                hintText: 'Doe',
                validator: Validators.name,
                textInputAction: TextInputAction.next,
              ),
            ),
          ]),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _dobCtl,
            label: 'Date of Birth',
            hintText: 'MM/DD/YYYY',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _pickDate(context),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Date of birth is required' : null,
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _emailCtl,
            label: 'Email',
            hintText: 'john@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _phoneCtl,
            label: 'Phone Number',
            hintText: '(555) 555-5555',
            keyboardType: TextInputType.phone,
            inputFormatters: [_PhoneFormatter()],
            validator: Validators.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 22),

          // Address section
          const Text('Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _streetCtl,
            label: 'Street Address',
            hintText: '123 Main St',
            validator: (v) => Validators.required(v, fieldName: 'Street'),
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _aptCtl,
            label: 'Apt/Suite (Optional)',
            hintText: 'Apt 4B',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _cityCtl,
                label: 'City',
                hintText: 'New York',
                validator: (v) => Validators.required(v, fieldName: 'City'),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStateDropdown()),
          ]),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _zipCtl,
            label: 'ZIP Code',
            hintText: '10001',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            validator: (v) {
              if (v == null || v.length != 5) return 'Enter 5-digit ZIP';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 22),

          // Emergency contact
          const Text('Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _emergNameCtl,
            label: 'Contact Name',
            hintText: 'Jane Doe',
            validator: (v) => Validators.required(v, fieldName: 'Name'),
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _emergRelCtl,
            label: 'Relationship',
            hintText: 'Spouse, Parent, etc.',
            validator: (v) => Validators.required(v, fieldName: 'Relationship'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _emergPhoneCtl,
            label: 'Contact Phone',
            hintText: '(555) 555-5555',
            keyboardType: TextInputType.phone,
            inputFormatters: [_PhoneFormatter()],
            validator: Validators.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 22),

          // SSN
          const Text('Background Check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Required for background check. Securely encrypted.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _ssnCtl,
            label: 'Last 4 digits of SSN',
            hintText: '1234',
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) {
              if (v == null || v.length != 4) return 'Enter last 4 digits';
              return null;
            },
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: 28),

          CustomButton(
            onPressed: isSaving ? null : _save,
            isLoading: isSaving,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('State',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _usStates
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedState = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 21),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Must be at least 18 years old',
    );
    if (picked != null) {
      _dobCtl.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final info = PersonalInfo(
      firstName: _firstNameCtl.text.trim(),
      lastName: _lastNameCtl.text.trim(),
      dateOfBirth: _dobCtl.text.trim(),
      email: _emailCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      address: AddressInfo(
        street: _streetCtl.text.trim(),
        apartment: _aptCtl.text.trim().isEmpty ? null : _aptCtl.text.trim(),
        city: _cityCtl.text.trim(),
        state: _selectedState ?? '',
        zipCode: _zipCtl.text.trim(),
      ),
      emergencyContact: EmergencyContact(
        name: _emergNameCtl.text.trim(),
        relationship: _emergRelCtl.text.trim(),
        phone: _emergPhoneCtl.text.trim(),
      ),
      ssnLastFour: _ssnCtl.text.trim(),
    );

    await ref.read(heroApplicationProvider.notifier).savePersonalInfo(info);
  }

  static const _usStates = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
  ];
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 10; i++) {
      if (i == 0) buf.write('(');
      if (i == 3) buf.write(') ');
      if (i == 6) buf.write('-');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }
}
