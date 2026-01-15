import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../design/text_styles.dart';

class PlatePhoto extends StatelessWidget {
  const PlatePhoto({
    super.key,
    required this.imageBytes,
    required this.plateAsset,
    this.plateSize = 300,
    this.imageSize = 210,
    this.tilt = -0.08,
    this.badgeCount,
  });

  final Uint8List imageBytes;
  final String plateAsset;
  final double plateSize;
  final double imageSize;
  final double tilt;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final showBadge = (badgeCount ?? 0) > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.rotate(
          angle: tilt,
          child: SizedBox.square(
            dimension: plateSize,
            child: RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    plateAsset,
                    fit: BoxFit.contain,
                    cacheWidth: (plateSize * 2).round(),
                    gaplessPlayback: true,
                  ),
                  Container(
                    width: plateSize * 0.92,
                    height: plateSize * 0.92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.25),
                        ],
                        stops: const [0.6, 1],
                      ),
                    ),
                  ),
                  ClipOval(
                    child: Image.memory(
                      imageBytes,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      cacheWidth: (imageSize * 2).round(),
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: -10,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('+$badgeCount', style: AppTextStyles.caption(context).copyWith(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
