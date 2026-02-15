import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job_model.dart';

class HeroInfoCard extends StatelessWidget {
  final JobHero hero;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const HeroInfoCard({
    super.key,
    required this.hero,
    this.onChat,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    child: ClipOval(
                      child: hero.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: hero.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey[200], child: const Icon(Icons.person)),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.person)),
                            )
                          : Container(color: Colors.grey[200], child: const Icon(Icons.person, size: 30)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hero.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (hero.vehicleMake != null && hero.vehicleModel != null)
                          Text('${hero.vehicleColor ?? ''} ${hero.vehicleMake} ${hero.vehicleModel}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        if (hero.licensePlate != null)
                          Text(hero.licensePlate!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
