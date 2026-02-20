import 'package:flutter/material.dart';

class TurnInstruction extends StatelessWidget {
  final String instruction;
  final String maneuver;
  final double? distanceMeters;
  final String? streetName;

  const TurnInstruction({
    super.key,
    required this.instruction,
    required this.maneuver,
    this.distanceMeters,
    this.streetName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_maneuverIcon(maneuver), color: Colors.black, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (streetName != null)
                  Text(
                    streetName!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
              ],
            ),
          ),
          if (distanceMeters != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDistance(distanceMeters!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _maneuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'uturn-left':
        return Icons.u_turn_left;
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
        return Icons.fork_left;
      case 'fork-right':
        return Icons.fork_right;
      case 'roundabout':
        return Icons.roundabout_left;
      case 'arrive':
        return Icons.flag;
      case 'depart':
        return Icons.navigation;
      default:
        return Icons.straight;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1609.34).toStringAsFixed(1)} mi';
  }
}
