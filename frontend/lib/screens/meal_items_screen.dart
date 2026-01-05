import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/meal_entry.dart';
import 'meal_detail_screen.dart';

class MealItemsScreen extends StatefulWidget {
  const MealItemsScreen({super.key, required this.group});

  final List<MealEntry> group;

  @override
  State<MealItemsScreen> createState() => _MealItemsScreenState();
}

class _MealItemsScreenState extends State<MealItemsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _itemCard(BuildContext context, MealEntry entry) {
    final t = AppLocalizations.of(context)!;
    const double plateSize = 320;
    const double imageSize = 220;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
      child: Container(
        height: 420,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: plateSize,
                  height: plateSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipOval(
                          child: Image.asset('assets/plates/plate_default.png', fit: BoxFit.cover),
                        ),
                      ),
                      Center(
                        child: ClipOval(
                          child: Image.memory(
                            entry.imageBytes,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('${t.portionLabel} ${entry.portionPercent}%', style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sorted = List<MealEntry>.from(widget.group)..sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      appBar: AppBar(
        title: Text(t.mealItemsTitle),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          height: 460,
          child: PageView.builder(
            controller: _pageController,
            itemCount: sorted.length,
            itemBuilder: (context, index) => _itemCard(context, sorted[index]),
          ),
        ),
      ),
    );
  }
}
