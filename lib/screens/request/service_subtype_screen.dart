import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/common/step_progress_indicator.dart';
import 'vehicle_info_screen.dart';

class ServiceSubTypeScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final List<SubTypeOption> options;
  final bool allowMultiple;
  final String? subtitle;

  const ServiceSubTypeScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    required this.options,
    this.allowMultiple = false,
    this.subtitle,
  });

  @override
  State<ServiceSubTypeScreen> createState() => _ServiceSubTypeScreenState();
}

class _ServiceSubTypeScreenState extends State<ServiceSubTypeScreen> {
  final Set<String> _selected = {};

  bool get _hasSelection => _selected.isNotEmpty;

  String get _selectionSummary {
    final titles = widget.options
        .where((o) => _selected.contains(o.id))
        .map((o) => o.title)
        .toList();
    return titles.join(' + ');
  }

  void _toggle(String id) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      } else {
        if (_selected.contains(id)) {
          _selected.clear();
        } else {
          _selected
            ..clear()
            ..add(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultSubtitle = widget.allowMultiple
        ? 'Select one or both options'
        : 'Select the type of assistance you require';

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
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StepProgressIndicator(currentStep: 1, totalSteps: 4),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What do you need?',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle ?? defaultSubtitle,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),

                    ...widget.options.map((option) {
                      final isSelected = _selected.contains(option.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _toggle(option.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.brandGreen
                                    : const Color(0xFFE8E8E8),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.brandGreen
                                        : const Color(0xFFF2F2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.brandGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildIndicator(isSelected),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Selected summary for multi-select
                    if (widget.allowMultiple && _hasSelection) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Text(
                          'Selected: $_selectionSummary',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Continue button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _hasSelection ? _onContinue : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildIndicator(bool isSelected) {
    if (widget.allowMultiple) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : const Color(0xFFD0D0D0),
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      );
    }
    return isSelected
        ? Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.brandGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          )
        : const SizedBox.shrink();
  }

  void _onContinue() {
    final subType = _selected.join('+');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleInfoScreen(
          serviceType: widget.serviceType,
          serviceLabel: widget.serviceLabel,
          subType: subType,
          totalSteps: 4,
        ),
      ),
    );
  }
}

class SubTypeOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const SubTypeOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
