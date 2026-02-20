import 'package:flutter/material.dart';

class CustomerMarkerIcon extends StatelessWidget {
  final double size;

  const CustomerMarkerIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
