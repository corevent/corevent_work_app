import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'work_widgets.dart';

class CoreventProfileAvatar extends StatelessWidget {
  const CoreventProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 36,
  });
  final String name;
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final hasImage = url?.trim().isNotEmpty == true;
    final letters = initials(name);
    return Semantics(
      image: true,
      label: 'Foto de perfil de $name',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.orangeSoft,
        foregroundImage: hasImage ? NetworkImage(url!) : null,
        onForegroundImageError: hasImage ? (_, _) {} : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            child: Text(
              letters.isEmpty ? 'C' : letters,
              style: TextStyle(
                fontSize: radius * .62,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
