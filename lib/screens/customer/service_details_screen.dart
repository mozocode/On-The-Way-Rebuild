import 'package:flutter/material.dart';
import '../../models/service_type_model.dart';
import '../../config/theme.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceTypeModel service;
  final void Function(String? subType, String? notes) onConfirm;

  const ServiceDetailsScreen({
    super.key,
    required this.service,
    required this.onConfirm,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  String? _selectedSubType;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(_serviceIcon(widget.service.id),
                              size: 48, color: AppTheme.brandGreen),
                          const SizedBox(height: 12),
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.service.description,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _InfoChip(
                                icon: Icons.attach_money,
                                label:
                                    'From \$${(widget.service.basePrice / 100).toStringAsFixed(0)}',
                              ),
                              const SizedBox(width: 12),
                              _InfoChip(
                                icon: Icons.schedule,
                                label:
                                    '~${widget.service.estimatedDuration ?? 30} min',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (widget.service.subTypes.isNotEmpty) ...[
                      const Text(
                        'What do you need?',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...widget.service.subTypes.map((sub) {
                        final isSelected = sub == _selectedSubType;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChoiceChip(
                            label: Text(_formatSubType(sub)),
                            selected: isSelected,
                            selectedColor: AppTheme.brandGreen.withOpacity(0.2),
                            onSelected: (selected) {
                              setState(() {
                                _selectedSubType = selected ? sub : null;
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'Additional Notes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe your issue or any details the hero should know...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm(
                    _selectedSubType,
                    _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSubType(String sub) {
    return sub.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  IconData _serviceIcon(String id) {
    switch (id) {
      case 'flat_tire':
        return Icons.circle_outlined;
      case 'dead_battery':
        return Icons.battery_0_bar;
      case 'lockout':
        return Icons.key;
      case 'fuel_delivery':
        return Icons.local_gas_station;
      case 'towing':
        return Icons.local_shipping;
      case 'winch_out':
        return Icons.warning;
      default:
        return Icons.build;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.brandGreen),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
