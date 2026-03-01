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
  bool _expanded = true;
  bool _dragging = false;
  double _dial = 0;
  double _verticalDragDelta = 0;

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
    if (_expanded) return;
    setState(() => _expanded = true);
  }

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  void _selectIndex(int index, {bool collapse = false}) {
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

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: _expanded ? 1 : 0),
      builder: (context, expand, _) {
        final barHeight = 90 + expand * 96;
        final barLift = expand * 96;
        final activeIndex = _wrapIndex(_dial.round());
        return SizedBox(
          height: barHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            child: Transform.translate(
              offset: Offset(0, -barLift),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_expanded) {
                    _expand();
                  }
                },
                onVerticalDragStart: (_) {
                  _verticalDragDelta = 0;
                },
                onVerticalDragUpdate: (details) {
                  _verticalDragDelta += details.delta.dy;
                },
                onVerticalDragEnd: (_) {
                  if (_verticalDragDelta > 18) {
                    _collapse();
                  } else if (_verticalDragDelta < -18) {
                    _expand();
                  }
                  _verticalDragDelta = 0;
                },
                onHorizontalDragStart: (_) {
                  _dragging = true;
                  _expand();
                },
                onHorizontalDragUpdate: (details) {
                  final next = _wrapDial(_dial - details.delta.dx / 74);
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
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 11),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final centerX = constraints.maxWidth / 2;
                      final itemWidth = 72 + expand * 16;
                      final itemHeight = itemWidth + 26;
                      final spacing = 74 + expand * 34;
                      final visibleDelta = 1.0 + expand * 1.0;

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (var i = 0; i < widget.items.length; i++)
                            Builder(builder: (context) {
                              final delta = _wrappedDelta(i, _dial);
                              if (delta.abs() > visibleDelta + 0.34) {
                                return const SizedBox.shrink();
                              }
                              final focus =
                                  (1 - (delta.abs() / 2.8)).clamp(0.0, 1.0);
                              final edgeFade =
                                  ((visibleDelta + 0.3 - delta.abs()) / 0.48)
                                      .clamp(0.0, 1.0);
                              final x = delta * spacing;
                              final arcY = math.pow(delta.abs(), 1.45) *
                                  (8 + expand * 3);
                              final top = 52 + arcY - expand * 50;
                              final scale = 0.9 + expand * (0.25 + focus * 0.22);
                              final iconSize = 22 + expand * (12 + focus * 10);
                              final active = _wrapIndex(i) == activeIndex;
                              final iconColor =
                                  active ? activeColor : inactiveColor;
                              final tilt = delta * 0.095 * expand;

                              return Positioned(
                                top: top,
                                left: centerX + x - itemWidth / 2,
                                width: itemWidth,
                                height: itemHeight,
                                child: Transform.rotate(
                                  angle: tilt,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: edgeFade,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () {
                                            if (!_expanded) {
                                              _expand();
                                            }
                                            _selectIndex(i);
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: itemWidth,
                                                height: itemWidth,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: active
                                                      ? activeColor.withValues(
                                                          alpha: 0.18)
                                                      : Colors.white.withValues(
                                                          alpha:
                                                              0.65 + focus * 0.2),
                                                  border: Border.all(
                                                    color: active
                                                        ? activeColor.withValues(
                                                            alpha: 0.45)
                                                        : Colors.black
                                                            .withValues(
                                                                alpha: 0.08),
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
                                              const SizedBox(height: 4),
                                              SizedBox(
                                                width: itemWidth + 24,
                                                child: Text(
                                                  widget.items[i].label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    fontSize: 11 +
                                                        expand * 1.2,
                                                    fontWeight: active
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: active
                                                        ? activeColor
                                                        : theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha:
                                                                    0.7),
                                                  ),
                                                ),
                                              ),
                                            ],
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
    );
  }
}
