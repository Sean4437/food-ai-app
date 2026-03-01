import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class RevolverTabItem {
  const RevolverTabItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.assetImage,
  });

  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final String? assetImage;
}

class RevolverTabBar extends StatefulWidget {
  const RevolverTabBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  final int currentIndex;
  final List<RevolverTabItem> items;
  final ValueChanged<int> onSelect;

  @override
  State<RevolverTabBar> createState() => _RevolverTabBarState();
}

class _RevolverTabBarState extends State<RevolverTabBar> {
  bool _expanded = false;
  bool _dragging = false;
  double _dial = 0;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _dial = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant RevolverTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_dragging) {
      _dial = widget.currentIndex.toDouble();
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  int _wrapIndex(int index) {
    final n = widget.items.length;
    var value = index % n;
    if (value < 0) value += n;
    return value;
  }

  double _wrapDial(double value) {
    final n = widget.items.length.toDouble();
    var result = value % n;
    if (result < 0) result += n;
    return result;
  }

  double _wrappedDelta(int index, double dial) {
    final n = widget.items.length.toDouble();
    var delta = index - dial;
    if (delta > n / 2) delta -= n;
    if (delta < -n / 2) delta += n;
    return delta;
  }

  void _expand() {
    _collapseTimer?.cancel();
    if (_expanded) return;
    setState(() => _expanded = true);
  }

  void _collapse({Duration delay = const Duration(milliseconds: 220)}) {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _expanded = false);
    });
  }

  void _selectIndex(int index, {bool collapse = true}) {
    final wrapped = _wrapIndex(index);
    setState(() => _dial = wrapped.toDouble());
    if (wrapped != widget.currentIndex) {
      widget.onSelect(wrapped);
    }
    if (collapse) {
      _collapse();
    }
  }

  Widget _buildIcon(
    RevolverTabItem item,
    bool active,
    double size,
    Color color,
  ) {
    final image = item.assetImage?.trim() ?? '';
    if (image.isNotEmpty) {
      return Opacity(
        opacity: active ? 1 : 0.72,
        child: Image.asset(image, width: size, height: size),
      );
    }
    return Icon(
      active ? (item.activeIcon ?? item.icon) : item.icon,
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return SafeArea(
      top: false,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: _expanded ? 1 : 0),
        builder: (context, expand, _) {
          final barHeight = 78 + expand * 34;
          final barLift = expand * 24;
          final activeIndex = _wrapIndex(_dial.round());
          return SizedBox(
            height: barHeight + 10,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Transform.translate(
                offset: Offset(0, -barLift),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_expanded) {
                      setState(() => _expanded = false);
                    } else {
                      _expand();
                    }
                  },
                  onHorizontalDragStart: (_) {
                    _dragging = true;
                    _expand();
                  },
                  onHorizontalDragUpdate: (details) {
                    final next = _wrapDial(_dial - details.delta.dx / 58);
                    setState(() => _dial = next);
                  },
                  onHorizontalDragEnd: (_) {
                    _dragging = false;
                    _selectIndex(_dial.round());
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFBFCFB), Color(0xFFE8EEE9)],
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final centerX = constraints.maxWidth / 2;
                        const itemWidth = 58.0;
                        const spacing = 54.0;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 8 - expand * 2,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: expand,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.86),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.black.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Text(
                                        widget.items[activeIndex].label,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            for (var i = 0; i < widget.items.length; i++)
                              Builder(builder: (context) {
                                final delta = _wrappedDelta(i, _dial);
                                final focus = (1 - (delta.abs() / 2.8)).clamp(0.0, 1.0);
                                final x = delta * spacing;
                                final arcY = math.pow(delta.abs(), 1.45) * 5.4;
                                final top = 30 + arcY - expand * 20;
                                final scale = 0.86 + expand * (0.24 + focus * 0.2);
                                final iconSize = 18 + expand * (8 + focus * 8);
                                final active = _wrapIndex(i) == activeIndex;
                                final iconColor = active ? activeColor : inactiveColor;
                                final tilt = delta * 0.1 * expand;

                                return Positioned(
                                  top: top,
                                  left: centerX + x - itemWidth / 2,
                                  width: itemWidth,
                                  height: itemWidth,
                                  child: Transform.rotate(
                                    angle: tilt,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {
                                            if (!_expanded) {
                                              _expand();
                                            }
                                            _selectIndex(i);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: active
                                                  ? activeColor.withValues(alpha: 0.18)
                                                  : Colors.white.withValues(
                                                      alpha: 0.65 + focus * 0.2),
                                              border: Border.all(
                                                color: active
                                                    ? activeColor.withValues(alpha: 0.45)
                                                    : Colors.black
                                                        .withValues(alpha: 0.08),
                                              ),
                                            ),
                                            child: Center(
                                              child: _buildIcon(
                                                widget.items[i],
                                                active,
                                                iconSize,
                                                iconColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
