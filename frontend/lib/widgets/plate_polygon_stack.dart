import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'plate_photo.dart';

class PlatePolygonStack extends StatelessWidget {
  const PlatePolygonStack({
    super.key,
    required this.images,
    required this.plateAsset,
    this.selectedIndex = 0,
    this.onSelect,
    this.onOpen,
    this.maxPlateSize = 300,
    this.minPlateSize = 220,
  });

  final List<Uint8List> images;
  final String plateAsset;
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
        var plateSize = maxPlateSize * 0.85;
        if (plateSize < minPlateSize) {
          plateSize = minPlateSize;
        }
        var radius = plateSize * 0.7;
        final outerCount = count <= 5 ? count : math.min(6, count);
        final innerCount = count - outerCount;
        final offsets = <Offset>[];
        if (count == 1) {
          offsets.add(Offset.zero);
        } else if (count == 2) {
          offsets.add(Offset(-radius * 0.7, -radius * 0.35));
          offsets.add(Offset(radius * 0.7, radius * 0.35));
        } else {
          final outerStep = 2 * math.pi / outerCount;
          final startAngle = -math.pi / 2;
          for (var i = 0; i < outerCount; i++) {
            final angle = startAngle + outerStep * i;
            offsets.add(Offset(radius * math.cos(angle), radius * math.sin(angle)));
          }
          if (innerCount > 0) {
            final innerRadius = radius * 0.48;
            final innerStep = 2 * math.pi / innerCount;
            final innerStart = -math.pi / 2 + innerStep / 2;
            for (var i = 0; i < innerCount; i++) {
              final angle = innerStart + innerStep * i;
              offsets.add(Offset(innerRadius * math.cos(angle), innerRadius * math.sin(angle)));
            }
          }
        }

        double minX = double.infinity;
        double maxX = -double.infinity;
        double minY = double.infinity;
        double maxY = -double.infinity;
        for (final offset in offsets) {
          minX = math.min(minX, offset.dx - plateSize / 2);
          maxX = math.max(maxX, offset.dx + plateSize / 2);
          minY = math.min(minY, offset.dy - plateSize / 2);
          maxY = math.max(maxY, offset.dy + plateSize / 2);
        }
        final boundsWidth = maxX - minX;
        final boundsHeight = maxY - minY;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final availableWidth = maxWidth > 0 ? maxWidth : boundsWidth;
        final availableHeight = maxHeight > 0 ? maxHeight : boundsHeight;
        final widthScale = availableWidth > 0 && boundsWidth > 0 ? availableWidth / boundsWidth : 1.0;
        final heightScale = availableHeight > 0 && boundsHeight > 0 ? availableHeight / boundsHeight : 1.0;
        final scale = math.min(1.0, math.min(widthScale, heightScale));
        if (scale < 1.0) {
          plateSize *= scale;
          radius *= scale;
          minX *= scale;
          maxX *= scale;
          minY *= scale;
          maxY *= scale;
        }
        final imageSize = plateSize * 0.7;
        final size = math.max(boundsWidth * scale, boundsHeight * scale);
        final center = Offset(availableWidth / 2, availableHeight / 2);
        final positions = offsets
            .map((offset) => center + offset * scale)
            .toList();

        final safeSelected = selectedIndex.clamp(0, count - 1);
        final drawOrder = <int>[
          for (var i = 0; i < count; i++) if (i != safeSelected) i,
          safeSelected,
        ];

        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final index in drawOrder)
                Positioned(
                  left: positions[index].dx - plateSize / 2,
                  top: positions[index].dy - plateSize / 2,
                  child: GestureDetector(
                    onTap: onOpen == null ? null : () => onOpen!(index),
                    onLongPress: onSelect == null ? null : () => onSelect!(index),
                      child: Transform.scale(
                        scale: index == safeSelected ? 1.08 : 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(index == safeSelected ? 0.18 : 0.08),
                              blurRadius: index == safeSelected ? 26 : 16,
                              offset: Offset(0, index == safeSelected ? 16 : 10),
                            ),
                          ],
                        ),
                        child: PlatePhoto(
                          imageBytes: images[index],
                          plateAsset: plateAsset,
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
