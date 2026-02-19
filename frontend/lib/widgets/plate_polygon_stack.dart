import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'plate_photo.dart';

class PlatePolygonStack extends StatelessWidget {
  const PlatePolygonStack({
    super.key,
    required this.images,
    required this.plateAsset,
    this.imageUrls,
    this.selectedIndex = 0,
    this.onSelect,
    this.onOpen,
    this.maxPlateSize = 300,
    this.minPlateSize = 220,
  });

  final List<Uint8List> images;
  final String plateAsset;
  final List<String?>? imageUrls;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final ValueChanged<int>? onOpen;
  final double maxPlateSize;
  final double minPlateSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = images.length;
        if (count == 0) return const SizedBox.shrink();
        final urls = imageUrls;
        var plateSize = maxPlateSize * 0.85;
        final maxWidth = constraints.maxWidth;
        if (maxWidth > 0) {
          final maxAllowed = maxWidth;
          plateSize = plateSize.clamp(minPlateSize, maxAllowed);
        }
        var radius = plateSize * 0.7;
        if (maxWidth > 0) {
          radius = math.min(radius, (maxWidth - plateSize) / 2);
        }
        var size = plateSize + radius * 2;
        final imageSize = plateSize * 0.7;
        final center = Offset((maxWidth > 0 ? maxWidth : size) / 2, size / 2);
        final outerCount = count <= 5 ? count : math.min(6, count);
        final innerCount = count - outerCount;
        final positions = <Offset>[];
        if (count == 1) {
          positions.add(center);
        } else if (count == 2) {
          positions.add(center + Offset(-radius * 0.7, -radius * 0.35));
          positions.add(center + Offset(radius * 0.7, radius * 0.35));
        } else {
          final outerStep = 2 * math.pi / outerCount;
          final startAngle = -math.pi / 2;
          for (var i = 0; i < outerCount; i++) {
            final angle = startAngle + outerStep * i;
            positions.add(center +
                Offset(radius * math.cos(angle), radius * math.sin(angle)));
          }
          if (innerCount > 0) {
            final innerRadius = radius * 0.48;
            final innerStep = 2 * math.pi / innerCount;
            final innerStart = -math.pi / 2 + innerStep / 2;
            for (var i = 0; i < innerCount; i++) {
              final angle = innerStart + innerStep * i;
              positions.add(center +
                  Offset(innerRadius * math.cos(angle),
                      innerRadius * math.sin(angle)));
            }
          }
        }

        final safeSelected = selectedIndex.clamp(0, count - 1);
        final drawOrder = <int>[
          for (var i = 0; i < count; i++)
            if (i != safeSelected) i,
          safeSelected,
        ];

        return SizedBox(
          width: maxWidth > 0 ? maxWidth : size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final index in drawOrder)
                Positioned(
                  left: positions[index].dx - plateSize / 2,
                  top: positions[index].dy - plateSize / 2,
                  child: GestureDetector(
                    onTap: onOpen == null ? null : () => onOpen!(index),
                    onLongPress:
                        onSelect == null ? null : () => onSelect!(index),
                    child: Transform.scale(
                      scale: index == safeSelected ? 1.08 : 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  index == safeSelected ? 0.18 : 0.08),
                              blurRadius: index == safeSelected ? 26 : 16,
                              offset:
                                  Offset(0, index == safeSelected ? 16 : 10),
                            ),
                          ],
                        ),
                        child: PlatePhoto(
                          imageBytes: images[index],
                          plateAsset: plateAsset,
                          imageUrl: urls != null && index < urls.length
                              ? urls[index]
                              : null,
                          plateSize: plateSize,
                          imageSize: imageSize,
                          tilt: index == safeSelected ? -0.08 : -0.02,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
