import 'package:flutter/material.dart';
import '../../models/service_type_model.dart';

class ServiceSelector extends StatelessWidget {
  final String? selectedServiceId;
  final void Function(ServiceTypeModel service) onSelect;

  const ServiceSelector({
    super.key,
    this.selectedServiceId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ServiceTypes.all
          .map((service) => _ServiceTile(
                service: service,
                isSelected: service.id == selectedServiceId,
                onTap: () => onSelect(service),
              ))
          .toList(),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceTypeModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor.withOpacity(0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon(service.id),
                  color: isSelected ? theme.primaryColor : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                'From \$${(service.basePrice / 100).toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: theme.primaryColor, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String id) {
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
