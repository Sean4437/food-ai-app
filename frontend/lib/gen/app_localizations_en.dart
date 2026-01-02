// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Food AI MVP';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get quickAdd => 'Quick Add (Auto)';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get lateSnack => 'Late Snack';

  @override
  String get other => 'Other';

  @override
  String get timeLabel => 'Time';

  @override
  String get editTime => 'Edit Time';

  @override
  String get noEntries => 'No entries yet';

  @override
  String get mealTotal => 'Meal total (est.)';

  @override
  String get todayMeals => 'Today Meals';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get captureTitle => 'Capture';

  @override
  String get captureHint => 'Snap what you are eating and you\'re done.';

  @override
  String get optionalNoteLabel => 'Optional note';

  @override
  String get notePlaceholder => 'e.g. half portion, take-away';

  @override
  String get recentPhotos => 'Recent photos';

  @override
  String get noPhotos => 'No photos yet';

  @override
  String get analysisTitle => 'Meal analysis';

  @override
  String get analysisEmpty => 'No analysis yet. Take a photo to start.';

  @override
  String get foodNameLabel => 'Food name';

  @override
  String get editFoodName => 'Edit food name';

  @override
  String get reanalyzeLabel => 'Reanalyze';

  @override
  String get unknownFood => 'Unnamed meal';

  @override
  String get dietitianPrefix => 'Advice: ';

  @override
  String get dietitianBalanced => 'Overall balanced. Keep it up.';

  @override
  String get dietitianProteinLow => 'Protein is low. Add lean protein.';

  @override
  String get dietitianFatHigh => 'Fat is high. Go lighter next meal.';

  @override
  String get dietitianCarbHigh => 'Carbs are high. Reduce starch.';

  @override
  String get dietitianSodiumHigh => 'Sodium is high. Cut broth and processed foods.';

  @override
  String get overallLabel => 'Overall';

  @override
  String get calorieLabel => 'Calorie range';

  @override
  String get macroLabel => 'Macros';

  @override
  String get levelLow => 'Low';

  @override
  String get levelMedium => 'Medium';

  @override
  String get levelHigh => 'High';

  @override
  String get statusOk => 'OK';

  @override
  String get statusWarn => 'A bit high';

  @override
  String get statusOver => 'Too much';

  @override
  String get tagOily => 'Oily';

  @override
  String get tagProteinOk => 'Protein OK';

  @override
  String get tagProteinLow => 'Low protein';

  @override
  String get tagCarbHigh => 'Carbs high';

  @override
  String get tagOk => 'OK';

  @override
  String get nextMealTitle => 'How to balance your next meal';

  @override
  String get nextMealHint => 'Pick the easiest option for you';

  @override
  String get optionConvenienceTitle => 'Convenience store';

  @override
  String get optionConvenienceDesc =>
      'Eggs, unsweetened soy milk, salad. Skip fried foods.';

  @override
  String get optionBentoTitle => 'Bento shop';

  @override
  String get optionBentoDesc => 'Half rice, more veggies, grilled or braised.';

  @override
  String get optionLightTitle => 'Light choice';

  @override
  String get optionLightDesc => 'Soup, steamed foods, less sauce.';

  @override
  String get summaryTitle => 'Today summary';

  @override
  String get summaryEmpty => 'No meals recorded today';

  @override
  String get summaryOilyCarb => 'A bit oily and carb-heavy today';

  @override
  String get summaryOily => 'A bit oily today';

  @override
  String get summaryCarb => 'Carbs are a bit high today';

  @override
  String get summaryProteinOk => 'Protein is OK, add veggies if you can';

  @override
  String get summaryNeutral => 'Pretty good today, keep it up';

  @override
  String get mealsCountLabel => 'Logged';

  @override
  String get mealsLabel => 'meals';

  @override
  String get tabCapture => 'Capture';

  @override
  String get tabAnalysis => 'Analysis';

  @override
  String get tabNext => 'Next meal suggestions';

  @override
  String get tabSummary => 'Summary';

  @override
  String get tabHome => 'Home';

  @override
  String get tabLog => 'Log';

  @override
  String get tabSuggest => 'Suggest';

  @override
  String get tabSettings => 'Settings';

  @override
  String get greetingTitle => 'Hi, Alex';

  @override
  String get streakLabel => 'Streak: day 3';

  @override
  String get aiSuggest => 'AI food advice';

  @override
  String get latestMealTitle => 'Latest meal';

  @override
  String get latestMealEmpty => 'No meals yet';

  @override
  String get homeNextMealHint =>
      'Go to Suggestions and pick the easiest option';

  @override
  String get logTitle => 'Log';

  @override
  String get dailyCalorieRange => 'Today calorie range';

  @override
  String get calorieUnknown => 'Not estimated';

  @override
  String get detailTitle => 'Meal detail';

  @override
  String get detailAiLabel => 'AI explanation';

  @override
  String get detailAiEmpty => 'No analysis yet';

  @override
  String get detailWhyLabel => 'Why this result';

  @override
  String get suggestTitle => 'Suggestions';

  @override
  String get suggestTodayLabel => 'Today\'s status';

  @override
  String get suggestTodayHint => 'A bit oily today, go lighter next meal';

  @override
  String get suggestTodayOilyCarb => 'Oily and carb-heavy today';

  @override
  String get suggestTodayOily => 'A bit oily today, go lighter next meal';

  @override
  String get suggestTodayCarb => 'Carbs are high today, go lighter on starch';

  @override
  String get suggestTodayOk => 'Status looks OK today';

  @override
  String get logThisMeal => 'Log this meal';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileName => 'Alex';

  @override
  String get profileEmail => 'alex@example.com';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get planSection => 'Plan';

  @override
  String get heightLabel => 'Height';

  @override
  String get weightLabel => 'Weight';

  @override
  String get goalLabel => 'Goal';

  @override
  String get goalLoseFat => 'Lose fat';

  @override
  String get reminderSection => 'Reminders';

  @override
  String get reminderLunch => 'Lunch reminder';

  @override
  String get reminderDinner => 'Dinner reminder';

  @override
  String get subscriptionSection => 'Subscription';

  @override
  String get subscriptionPlan => 'Current plan';

  @override
  String get planMonthly => 'Fat loss \$199/mo';

  @override
  String get languageLabel => 'Language';

  @override
  String get langZh => 'Traditional Chinese';

  @override
  String get langEn => 'English';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get goalMaintain => 'Maintain weight';

  @override
  String get planSpeedLabel => 'Fat loss speed';

  @override
  String get planSpeedStable => 'Steady';

  @override
  String get planSpeedGentle => 'Gentle';

  @override
  String get reminderLunchTime => 'Lunch reminder time';

  @override
  String get reminderDinnerTime => 'Dinner reminder time';

  @override
  String get pickFromCamera => 'Camera';

  @override
  String get pickFromGallery => 'Choose from gallery';

  @override
  String get addMeal => 'Add';

  @override
  String get noMealPrompt => 'No record yet. Take a quick photo.';

  @override
  String get layoutThemeLabel => 'Theme & layout';

  @override
  String get themeClean => 'Clean Blue';

  @override
  String get themeWarm => 'Warm Orange';

  @override
  String get apiSection => 'API';

  @override
  String get apiBaseUrlLabel => 'API base URL';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Delete this record?';

  @override
  String get logSuccess => 'Meal logged';

  @override
  String get viewLog => 'View log';

  @override
  String get calories => 'Calories';

  @override
  String get estimated => 'estimated';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get sodium => 'Sodium';

  @override
  String get tier => 'Tier';

  @override
  String get analyzeFailed => 'Analyze failed';

  @override
  String get costEstimateLabel => 'Estimated cost';

  @override
  String get usageSection => 'AI cost';

  @override
  String get usageTotalLabel => 'Total spent';

  @override
  String get usageViewLog => 'View history';

  @override
  String get usageEmpty => 'No cost records yet';

  @override
  String get usageLoading => 'Loading...';

  @override
  String get mockPrefix => 'Mock';

  @override
  String get versionSection => 'Version info';

  @override
  String get versionBuild => 'Build time';

  @override
  String get versionCommit => 'Commit';

  @override
  String get versionUnavailable => 'Version info unavailable';
}
