import 'package:flutter/material.dart';
import '../../models/route_model.dart';

class NavigationHeader extends StatelessWidget {
  final RouteStep step;
  final String? destinationAddress;

  const NavigationHeader({
    super.key,
    required this.step,
    this.destinationAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getManeuverIcon(step.maneuver), color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (step.streetName != null)
                  Text(step.streetName!, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              step.distance < 1000 ? '${step.distance.round()} m' : '${(step.distance / 1000).toStringAsFixed(1)} km',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left': return Icons.turn_left;
      case 'turn-right': return Icons.turn_right;
      case 'arrive': return Icons.flag;
      case 'depart': return Icons.navigation;
      default: return Icons.straight;
    }
  }
}
