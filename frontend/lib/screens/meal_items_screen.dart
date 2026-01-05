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

  double get _cardHeight => 240;

  Widget _itemCard(BuildContext context, MealEntry entry) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
      child: Container(
        height: _cardHeight,
        padding: const EdgeInsets.all(14),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(entry.imageBytes, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
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
          height: 320,
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
