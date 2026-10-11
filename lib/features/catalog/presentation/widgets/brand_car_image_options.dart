import 'package:flutter/material.dart';

class BrandCarImageOption {
  const BrandCarImageOption({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

const brandCarImageOptions = <BrandCarImageOption>[
  BrandCarImageOption(
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFFCFDCE5),
  ),
  BrandCarImageOption(
    icon: Icons.electric_car_rounded,
    color: Color(0xFFE65462),
  ),
  BrandCarImageOption(icon: Icons.local_taxi_rounded, color: Color(0xFFF1F2F4)),
  BrandCarImageOption(
    icon: Icons.directions_car_rounded,
    color: Color(0xFF58A9E8),
  ),
];
