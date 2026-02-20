import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/hero_application_model.dart';
import '../../../providers/hero_application_provider.dart';
import '../../../widgets/common/custom_button.dart';

class ServicesStep extends ConsumerStatefulWidget {
  const ServicesStep({super.key});

  @override
  ConsumerState<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends ConsumerState<ServicesStep>
    with AutomaticKeepAliveClientMixin {
  // Services
  bool _flatTire = false;
  bool _deadBattery = false;
  bool _lockout = false;
  bool _fuelDelivery = false;
  bool _towing = false;
  bool _winchOut = false;

  // Equipment
  bool _jumpCables = false;
  bool _portableBatteryPack = false;
  bool _tireChangeKit = false;
  bool _jackAndLugWrench = false;
  bool _airCompressor = false;
  bool _lockoutKit = false;
  bool _fuelCan = false;
  bool _towStraps = false;
  bool _winch = false;
  bool _safetyVest = false;
  bool _flashlight = false;
  bool _trafficCones = false;
  bool _firstAidKit = false;

  int _yearsExperience = 0;
  double _maxRadius = 15;

  // Availability
  final Map<String, bool> _dayAvailability = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final caps =
        ref.read(heroApplicationProvider).application?.serviceCapabilities;
    if (caps == null) return;

    final s = caps.services;
    _flatTire = s.flatTire;
    _deadBattery = s.deadBattery;
    _lockout = s.lockout;
    _fuelDelivery = s.fuelDelivery;
    _towing = s.towing;
    _winchOut = s.winchOut;

    final e = caps.equipment;
    _jumpCables = e.jumpCables;
    _portableBatteryPack = e.portableBatteryPack;
    _tireChangeKit = e.tireChangeKit;
    _jackAndLugWrench = e.jackAndLugWrench;
    _airCompressor = e.airCompressor;
    _lockoutKit = e.lockoutKit;
    _fuelCan = e.fuelCan;
    _towStraps = e.towStraps;
    _winch = e.winch;
    _safetyVest = e.safetyVest;
    _flashlight = e.flashlight;
    _trafficCones = e.trafficCones;
    _firstAidKit = e.firstAidKit;

    _yearsExperience = caps.yearsExperience;
    _maxRadius = caps.maxServiceRadius.toDouble();

    final a = caps.availability;
    _dayAvailability['monday'] = a.monday.available;
    _dayAvailability['tuesday'] = a.tuesday.available;
    _dayAvailability['wednesday'] = a.wednesday.available;
    _dayAvailability['thursday'] = a.thursday.available;
    _dayAvailability['friday'] = a.friday.available;
    _dayAvailability['saturday'] = a.saturday.available;
    _dayAvailability['sunday'] = a.sunday.available;
  }

  bool get _hasService =>
      _flatTire || _deadBattery || _lockout || _fuelDelivery || _towing || _winchOut;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSaving = ref.watch(isApplicationSavingProvider);
    final error = ref.watch(applicationErrorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Services & Equipment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('What can you offer?',
            style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        const SizedBox(height: 20),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(error, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // ── Services ──
        const Text('Services You Can Provide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Select at least one service',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 12),

        _serviceToggle('Flat Tire Change', Icons.tire_repair, _flatTire,
            (v) => setState(() => _flatTire = v)),
        _serviceToggle('Dead Battery / Jump Start', Icons.battery_charging_full, _deadBattery,
            (v) => setState(() => _deadBattery = v)),
        _serviceToggle('Lockout Assistance', Icons.lock_open, _lockout,
            (v) => setState(() => _lockout = v)),
        _serviceToggle('Fuel Delivery', Icons.local_gas_station, _fuelDelivery,
            (v) => setState(() => _fuelDelivery = v)),
        _serviceToggle('Towing', Icons.local_shipping, _towing,
            (v) => setState(() => _towing = v)),
        _serviceToggle('Winch Out', Icons.settings_input_hdmi, _winchOut,
            (v) => setState(() => _winchOut = v)),

        const SizedBox(height: 24),

        // ── Equipment ──
        const Text('Equipment You Own',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _equipChip('Jump Cables', _jumpCables, (v) => setState(() => _jumpCables = v)),
            _equipChip('Battery Pack', _portableBatteryPack, (v) => setState(() => _portableBatteryPack = v)),
            _equipChip('Tire Change Kit', _tireChangeKit, (v) => setState(() => _tireChangeKit = v)),
            _equipChip('Jack & Lug Wrench', _jackAndLugWrench, (v) => setState(() => _jackAndLugWrench = v)),
            _equipChip('Air Compressor', _airCompressor, (v) => setState(() => _airCompressor = v)),
            _equipChip('Lockout Kit', _lockoutKit, (v) => setState(() => _lockoutKit = v)),
            _equipChip('Fuel Can', _fuelCan, (v) => setState(() => _fuelCan = v)),
            _equipChip('Tow Straps', _towStraps, (v) => setState(() => _towStraps = v)),
            _equipChip('Winch', _winch, (v) => setState(() => _winch = v)),
            _equipChip('Safety Vest', _safetyVest, (v) => setState(() => _safetyVest = v)),
            _equipChip('Flashlight', _flashlight, (v) => setState(() => _flashlight = v)),
            _equipChip('Traffic Cones', _trafficCones, (v) => setState(() => _trafficCones = v)),
            _equipChip('First Aid Kit', _firstAidKit, (v) => setState(() => _firstAidKit = v)),
          ],
        ),

        const SizedBox(height: 24),

        // ── Experience ──
        const Text('Experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        const Text('Years of roadside assistance experience',
            style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _yearsExperience > 0
                  ? () => setState(() => _yearsExperience--)
                  : null,
            ),
            Text('$_yearsExperience',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _yearsExperience++),
            ),
            const SizedBox(width: 8),
            Text(_yearsExperience == 1 ? 'year' : 'years',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),

        const SizedBox(height: 24),

        // ── Service Radius ──
        const Text('Service Radius',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _maxRadius,
                min: 5,
                max: 50,
                divisions: 9,
                label: '${_maxRadius.round()} mi',
                onChanged: (v) => setState(() => _maxRadius = v),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text('${_maxRadius.round()} mi',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Availability ──
        const Text('Weekly Availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Select days you\'re typically available',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dayAvailability.entries.map((entry) {
            final label = entry.key[0].toUpperCase() + entry.key.substring(1);
            return FilterChip(
              label: Text(label),
              selected: entry.value,
              selectedColor: AppTheme.brandGreen.withAlpha(40),
              checkmarkColor: AppTheme.brandGreen,
              onSelected: (v) =>
                  setState(() => _dayAvailability[entry.key] = v),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

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
              onPressed: _hasService && !isSaving ? _save : null,
              isLoading: isSaving,
              child: const Text('Continue'),
            ),
          ),
        ]),

        if (!_hasService) ...[
          const SizedBox(height: 8),
          Text('Select at least one service to continue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _serviceToggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 22, color: value ? AppTheme.brandGreen : Colors.grey[500]),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.brandGreen,
      ),
    );
  }

  Widget _equipChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: value,
      selectedColor: AppTheme.brandGreen.withAlpha(40),
      checkmarkColor: AppTheme.brandGreen,
      onSelected: (v) => onChanged(v),
    );
  }

  Future<void> _save() async {
    DayAvailability _day(String key) =>
        DayAvailability(available: _dayAvailability[key] ?? false);

    final caps = ServiceCapabilities(
      services: ServicesOffered(
        flatTire: _flatTire,
        deadBattery: _deadBattery,
        lockout: _lockout,
        fuelDelivery: _fuelDelivery,
        towing: _towing,
        winchOut: _winchOut,
      ),
      equipment: EquipmentOwned(
        jumpCables: _jumpCables,
        portableBatteryPack: _portableBatteryPack,
        tireChangeKit: _tireChangeKit,
        jackAndLugWrench: _jackAndLugWrench,
        airCompressor: _airCompressor,
        lockoutKit: _lockoutKit,
        fuelCan: _fuelCan,
        towStraps: _towStraps,
        winch: _winch,
        safetyVest: _safetyVest,
        flashlight: _flashlight,
        trafficCones: _trafficCones,
        firstAidKit: _firstAidKit,
      ),
      yearsExperience: _yearsExperience,
      availability: WeeklyAvailability(
        monday: _day('monday'),
        tuesday: _day('tuesday'),
        wednesday: _day('wednesday'),
        thursday: _day('thursday'),
        friday: _day('friday'),
        saturday: _day('saturday'),
        sunday: _day('sunday'),
      ),
      maxServiceRadius: _maxRadius.round(),
    );

    await ref.read(heroApplicationProvider.notifier).saveServiceCapabilities(caps);
  }
}
