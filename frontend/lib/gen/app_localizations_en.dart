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
  String get brunch => 'Brunch';

  @override
  String get lunch => 'Lunch';

  @override
  String get afternoonTea => 'Afternoon tea';

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
  String get mealSummaryTitle => 'Dish summary';

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
  String get analysisEmpty => 'No analysis yet ??take a photo to start';

  @override
  String get foodNameLabel => 'Food name';

  @override
  String get editFoodName => 'Edit food name';

  @override
  String get reanalyzeLabel => 'Reanalyze';

  @override
  String get addLabel => 'Add label';

  @override
  String get removeLabel => 'Remove label';

  @override
  String get labelInfoTitle => 'Label info';

  @override
  String get labelSummaryFallback => 'Using label info';

  @override
  String get customTabTitle => 'Custom';

  @override
  String get customAdd => 'Add to custom';

  @override
  String get customAdded => 'Saved to custom';

  @override
  String get customEmpty => 'No custom items yet.';

  @override
  String get customSelectTitle => 'Choose a custom item';

  @override
  String get customConfirmTitle => 'Confirm meal info';

  @override
  String get customConfirmDate => 'Date';

  @override
  String get customConfirmTime => 'Time';

  @override
  String get customConfirmMealType => 'Meal type';

  @override
  String get customUse => 'Use custom item';

  @override
  String get customUseSaved => 'Custom meal saved';

  @override
  String get customCountUnit => 'items';

  @override
  String get customEditTitle => 'Edit custom item';

  @override
  String get customChangePhoto => 'Change photo';

  @override
  String get customSummaryLabel => 'Dish summary';

  @override
  String get customSuggestionLabel => 'Suggestion';

  @override
  String get customDeleteTitle => 'Delete custom item';

  @override
  String get customDeleteConfirm => 'Delete this custom item?';

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
  String get dietitianSodiumHigh =>
      'Sodium is high. Cut broth and processed foods.';

  @override
  String get multiItemsLabel => 'Multiple items';

  @override
  String get goalAdviceLoseFat =>
      'For fat loss, prioritize protein and vegetables next meal.';

  @override
  String get goalAdviceMaintain =>
      'For maintenance, keep portions and balance in check.';

  @override
  String get overallLabel => 'Overall';

  @override
  String get calorieLabel => 'Calorie range';

  @override
  String get editCalorieTitle => 'Edit calories';

  @override
  String get editCalorieHint => 'e.g. 450-600 kcal';

  @override
  String get editCalorieClear => 'Clear';

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
  String get nextMealSectionTitle => 'How to balance your next meal';

  @override
  String get noLateSnackSelfCook =>
      'No late snack; if needed, small clear soup + veggies';

  @override
  String get noLateSnackConvenience =>
      'No late snack; if needed, unsweetened soy milk or a small salad';

  @override
  String get noLateSnackBento =>
      'No late snack; if needed, half-portion veggie bento';

  @override
  String get noLateSnackOther =>
      'No late snack; if needed, a small portion of fruit';

  @override
  String get nextMealHint => 'Pick the easiest option for you';

  @override
  String get nextSelfCookLabel => 'Home-cook';

  @override
  String get nextConvenienceLabel => 'Convenience';

  @override
  String get nextBentoLabel => 'Bento';

  @override
  String get nextOtherLabel => 'Other';

  @override
  String get nextSelfCookHint => 'Steam/boil + veggies, light oil and sauce';

  @override
  String get nextConvenienceHint =>
      'Eggs, unsweetened soy milk, salad. Skip fried foods.';

  @override
  String get nextBentoHint => 'Half rice, more veggies, grilled or braised.';

  @override
  String get nextOtherHint => 'Fruit / unsweetened yogurt / clear soup';

  @override
  String get mealItemsTitle => 'Back to meal';

  @override
  String get mealTimeSection => 'Meal time ranges';

  @override
  String get breakfastStartLabel => 'Breakfast start';

  @override
  String get breakfastEndLabel => 'Breakfast end';

  @override
  String get brunchStartLabel => 'Brunch start';

  @override
  String get brunchEndLabel => 'Brunch end';

  @override
  String get lunchStartLabel => 'Lunch start';

  @override
  String get lunchEndLabel => 'Lunch end';

  @override
  String get afternoonTeaStartLabel => 'Afternoon tea start';

  @override
  String get afternoonTeaEndLabel => 'Afternoon tea end';

  @override
  String get dinnerStartLabel => 'Dinner start';

  @override
  String get dinnerEndLabel => 'Dinner end';

  @override
  String get lateSnackStartLabel => 'Late snack start';

  @override
  String get lateSnackEndLabel => 'Late snack end';

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
  String get summaryTitle => 'Today? summary';

  @override
  String get summaryEmpty => 'No meals recorded today yet';

  @override
  String get summaryOilyCarb => 'A bit oily and carb-heavy today';

  @override
  String get summaryOily => 'A bit oily today';

  @override
  String get summaryCarb => 'Carb-heavy today';

  @override
  String get summaryProteinOk => 'Protein looks OK ??add some veggies';

  @override
  String get summaryNeutral => 'You?e doing well today, keep it up';

  @override
  String get summaryBeverageOnly => 'Only beverages recorded today';

  @override
  String get includesBeverages => 'incl. beverages';

  @override
  String get proteinIntakeTodayLabel => 'Protein today';

  @override
  String proteinIntakeFormat(int consumed, int min, int max) {
    return 'Consumed ${consumed}g / Target $min-${max}g';
  }

  @override
  String get smallPortionNote => 'Small portion';

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
  String get tabSuggest => 'Instant';

  @override
  String get tabCustom => 'Custom';

  @override
  String get tabSettings => 'Settings';

  @override
  String greetingTitle(String name) {
    return 'Hi $name, you?e got this';
  }

  @override
  String streakLabel(int count) {
    return '$count-day streak';
  }

  @override
  String get aiSuggest => 'AI food advice';

  @override
  String get latestMealTitle => 'Latest meal';

  @override
  String get latestMealEmpty => 'You haven\'t logged any meals today';

  @override
  String get homeNextMealHint => 'Open Suggestions and pick the easiest option';

  @override
  String get logTitle => 'Log';

  @override
  String get logTopMealTitle => 'Highest calorie meal';

  @override
  String get logTopMealEmpty => 'No complete records in the past 7 days';

  @override
  String logRecentDaysTag(String date) {
    return 'Last 7 days $date';
  }

  @override
  String get logAddMealPrompt => 'Add this meal';

  @override
  String get dailyCalorieRange => 'Today calorie range';

  @override
  String get dayCardTitle => 'Daily summary';

  @override
  String get dayMealsTitle => 'Back to meals';

  @override
  String get tomorrowAdviceTitle => 'Tomorrow advice';

  @override
  String get dayCardDateLabel => 'Date:';

  @override
  String get dayCardCalorieLabel => 'Energy Status';

  @override
  String get dayCardProteinLabel => 'Protein Status';

  @override
  String get calorieHistoryTitle => 'Calorie Trend';

  @override
  String calorieTrendTargetLabel(String min, String max) {
    return 'Target $min-$max';
  }

  @override
  String get calorieTrendSummaryWeekTitle => 'Weekly Summary';

  @override
  String get calorieTrendSummaryTwoWeeksTitle => '2-Week Summary';

  @override
  String get calorieTrendSummaryMonthTitle => 'Monthly Summary';

  @override
  String get calorieTrendCompareLastWeek => 'last week';

  @override
  String get calorieTrendCompareLastTwoWeeks => 'previous 2 weeks';

  @override
  String get calorieTrendCompareLastMonth => 'last month';

  @override
  String get calorieTrendSummaryNoData => 'No data yet.';

  @override
  String calorieTrendSummaryNoPrev(String avg) {
    return 'Avg intake $avg kcal, no previous period data.';
  }

  @override
  String calorieTrendSummaryHigher(String avg, String period, String pct) {
    return 'Avg intake $avg kcal, higher than $period by $pct%.';
  }

  @override
  String calorieTrendSummaryLower(String avg, String period, String pct) {
    return 'Avg intake $avg kcal, lower than $period by $pct%.';
  }

  @override
  String calorieTrendSummarySame(String avg, String period) {
    return 'Avg intake $avg kcal, same as $period.';
  }

  @override
  String get proteinTrendTitle => 'Protein Trend';

  @override
  String proteinTrendTargetLabel(String value) {
    return 'Target $value g';
  }

  @override
  String get proteinTrendSummaryNoData => 'No data yet.';

  @override
  String proteinTrendSummaryNoPrev(String avg) {
    return 'Avg intake $avg g, no previous period data.';
  }

  @override
  String proteinTrendSummaryHigher(String avg, String period, String pct) {
    return 'Avg intake $avg g, higher than $period by $pct%.';
  }

  @override
  String proteinTrendSummaryLower(String avg, String period, String pct) {
    return 'Avg intake $avg g, lower than $period by $pct%.';
  }

  @override
  String proteinTrendSummarySame(String avg, String period) {
    return 'Avg intake $avg g, same as $period.';
  }

  @override
  String get dayCardMealsLabel => 'Meals analyzed:';

  @override
  String get dayCardSummaryLabel => 'Today\'s summary';

  @override
  String get dayCardTomorrowLabel => 'Tomorrow\'s advice';

  @override
  String summaryPendingAt(Object time) {
    return 'Summary will be ready at $time';
  }

  @override
  String weekSummaryPendingAt(Object day, Object time) {
    return 'Weekly summary will be ready on $day at $time';
  }

  @override
  String get finalizeDay => 'Generate today\'s summary';

  @override
  String get dishSummaryLabel => 'Meal summary';

  @override
  String get mealCountEmpty => 'No meals analyzed';

  @override
  String get calorieUnknown => 'Estimate not available yet';

  @override
  String get portionLabel => 'Portion';

  @override
  String get portionFull => 'Full';

  @override
  String get portionHalf => 'Half';

  @override
  String get portionBite => 'A few bites';

  @override
  String get detailTitle => 'Meal detail';

  @override
  String get detailAiLabel => 'AI explanation';

  @override
  String get detailAiEmpty => 'No analysis yet';

  @override
  String get detailWhyLabel => 'Why this result';

  @override
  String get suggestTitle => 'Instant Advice';

  @override
  String get suggestInstantHint => 'Snap a photo and get instant meal tips';

  @override
  String get suggestInstantStart => 'Take photo';

  @override
  String get suggestInstantRetake => 'Take next';

  @override
  String get suggestInstantPickGallery => 'Choose from album';

  @override
  String get suggestInstantNowEat => 'What to eat now';

  @override
  String get suggestInstantNameHint => 'Enter a food name (no photo needed)';

  @override
  String get suggestInstantNameSubmit => 'Analyze name';

  @override
  String get nameAnalyzeStart => 'Analyzing';

  @override
  String get nameAnalyzeEmpty => 'Enter a food name';

  @override
  String get suggestInstantStepDetect => 'Detecting meal';

  @override
  String get suggestInstantStepEstimate => 'Estimating calories and portions';

  @override
  String get suggestInstantStepAdvice => 'Generating tips';

  @override
  String get suggestInstantSavePrompt => 'Save this meal?';

  @override
  String get suggestInstantSave => 'Save';

  @override
  String get suggestInstantSkipSave => 'Not now';

  @override
  String get suggestInstantAdviceTitle => 'How to eat this dish better';

  @override
  String get suggestInstantCanEat => 'Good choices';

  @override
  String get suggestInstantCanDrink => 'Can drink';

  @override
  String get suggestInstantAvoid => 'Avoid';

  @override
  String get suggestInstantAvoidDrink => 'Avoid drinking';

  @override
  String get suggestInstantLimit => 'Suggested portion';

  @override
  String get suggestInstantDrinkLimit => 'Suggested amount';

  @override
  String get suggestInstantDrinkAdviceTitle => 'How to drink this beverage';

  @override
  String get suggestInstantCanEatInline => 'How to eat';

  @override
  String get suggestInstantRiskInline => 'Possible concerns';

  @override
  String get suggestInstantLimitInline => 'Suggested portion';

  @override
  String get suggestInstantEnergyOk => 'Acceptable';

  @override
  String get suggestInstantEnergyHigh => 'High';

  @override
  String get suggestInstantMissing => 'No analysis yet';

  @override
  String get suggestInstantNonFood =>
      'This doesn\'t look like food?ant to try another shot? If you\'re not eating now, come back when you\'re hungry.';

  @override
  String get suggestInstantReestimate => 'Re-estimate';

  @override
  String get suggestInstantRecentHint =>
      'Advice uses the last 7 days and the previous meal';

  @override
  String get suggestAutoSaved => 'Saved automatically';

  @override
  String get suggestTodayLabel => 'Today\'s status';

  @override
  String get suggestTodayHint =>
      'Fat is a bit high today ??keep the next meal lighter';

  @override
  String get suggestTodayOilyCarb => 'Oily and carb-heavy today';

  @override
  String get suggestTodayOily => 'A bit oily today, go lighter next meal';

  @override
  String get suggestTodayCarb => 'Carbs are high today, go lighter on starch';

  @override
  String get suggestTodayOk => 'You?e doing well today ??keep it up';

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
  String get nicknameLabel => 'Nickname';

  @override
  String get planSection => 'Plan';

  @override
  String get webTestSectionTitle => 'Web Test';

  @override
  String get webTestSubscriptionLabel => 'Test subscription';

  @override
  String get webTestEnabled => 'Enabled';

  @override
  String get webTestDisabled => 'Disabled';

  @override
  String get webTestPlanMonthly => 'Monthly (test)';

  @override
  String get webTestPlanYearly => 'Yearly (test)';

  @override
  String get webTestPlanNone => 'None';

  @override
  String get webTestAccessGraceLabel => 'Access grace hours';

  @override
  String get webTestAccessGraceDialogTitle => 'Access grace hours (1-168)';

  @override
  String webTestAccessGraceValue(int hours) {
    return '${hours}h';
  }

  @override
  String get accessStatusFailed =>
      'Verification failed. Please try again later.';

  @override
  String get heightLabel => 'Height';

  @override
  String get weightLabel => 'Weight';

  @override
  String get ageLabel => 'Age';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderUnspecified => 'Prefer not to say';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get bmiLabel => 'BMI';

  @override
  String get bmiUnderweight => 'Low';

  @override
  String get bmiNormal => 'Normal';

  @override
  String get bmiOverweight => 'High';

  @override
  String get bmiObese => 'Very high';

  @override
  String get goalLabel => 'Goal';

  @override
  String get goalLoseFat => 'Lose fat';

  @override
  String get reminderSection => 'Reminders';

  @override
  String get reminderTimeNote => 'Reminder time follows the meal start time';

  @override
  String get reminderBreakfast => 'Breakfast reminder';

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
  String get edit => 'Edit';

  @override
  String get editDaySummaryTitle => 'Edit daily summary';

  @override
  String get editMealAdviceTitle => 'Edit next-meal advice';

  @override
  String get goalMaintain => 'Maintain weight';

  @override
  String get planSpeedLabel => 'Fat loss speed';

  @override
  String get adviceStyleSection => 'Advice style';

  @override
  String get toneLabel => 'Tone';

  @override
  String get personaLabel => 'Persona';

  @override
  String get toneGentle => 'Gentle';

  @override
  String get toneDirect => 'Direct';

  @override
  String get toneEncouraging => 'Encouraging';

  @override
  String get toneBullet => 'Clear bullets';

  @override
  String get toneStrict => 'Strict';

  @override
  String get personaNutritionist => 'Nutritionist';

  @override
  String get personaCoach => 'Dining coach';

  @override
  String get personaFriend => 'Friend';

  @override
  String get personaSystem => 'Concise system';

  @override
  String get summarySettingsSection => 'Summary settings';

  @override
  String get summaryTimeLabel => 'Daily summary';

  @override
  String get weeklySummaryDayLabel => 'Weekly summary';

  @override
  String get weekTopMealTitle => 'Highest-calorie meal this week';

  @override
  String get recentGuidanceTitle => 'Recent guidance (last 7 days)';

  @override
  String get weekSummaryTitle => 'Weekly summary';

  @override
  String get nextWeekAdviceTitle => 'Next week advice';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get planSpeedStable => 'Steady';

  @override
  String get planSpeedGentle => 'Gentle';

  @override
  String get activityLevelLabel => 'Default activity';

  @override
  String get activityLabel => 'Activity level';

  @override
  String get activityCardTitle => 'Today activity';

  @override
  String get targetCalorieUnknown => 'Not estimated';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLight => 'Light';

  @override
  String get activityModerate => 'Moderate';

  @override
  String get activityHigh => 'High';

  @override
  String get exerciseNoExercise => 'No exercise';

  @override
  String get exerciseLabel => 'Exercise';

  @override
  String get exerciseMinutesLabel => 'Duration';

  @override
  String get exerciseMinutesUnit => 'min';

  @override
  String get exerciseMinutesHint => 'Enter minutes';

  @override
  String get exerciseCaloriesLabel => 'Exercise burn';

  @override
  String get exerciseNone => 'None';

  @override
  String get exerciseWalking => 'Brisk walk';

  @override
  String get exerciseJogging => 'Jogging';

  @override
  String get exerciseCycling => 'Cycling';

  @override
  String get exerciseSwimming => 'Swimming';

  @override
  String get exerciseStrength => 'Strength training';

  @override
  String get exerciseYoga => 'Yoga';

  @override
  String get exerciseHiit => 'HIIT';

  @override
  String get exerciseBasketball => 'Basketball';

  @override
  String get exerciseHiking => 'Hiking';

  @override
  String get deltaUnknown => 'Not estimated';

  @override
  String get deltaOk => 'Near target';

  @override
  String deltaSurplus(int kcal) {
    return 'Surplus $kcal kcal';
  }

  @override
  String deltaDeficit(int kcal) {
    return 'Deficit $kcal kcal';
  }

  @override
  String get commonExerciseLabel => 'Preferred exercise';

  @override
  String get suggestRemainingTitle => 'Calories remaining today';

  @override
  String suggestRemainingLeft(int cal) {
    return 'You can still have $cal kcal';
  }

  @override
  String suggestRemainingOver(int cal) {
    return 'Over by $cal kcal';
  }

  @override
  String proteinRemainingLeft(int grams) {
    return 'You can still have $grams g';
  }

  @override
  String proteinRemainingOver(int grams) {
    return 'Over by $grams g';
  }

  @override
  String suggestExerciseHint(String exercise, int minutes) {
    return 'Try $exercise for about $minutes min';
  }

  @override
  String get reminderLunchTime => 'Lunch reminder time';

  @override
  String get reminderDinnerTime => 'Dinner reminder time';

  @override
  String get reminderBreakfastTime => 'Breakfast reminder time';

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
  String get textSizeLabel => 'Text size';

  @override
  String get textSizeSmall => 'Standard';

  @override
  String get textSizeMedium => 'Larger';

  @override
  String get textSizeLarge => 'Largest';

  @override
  String get themeClean => 'Clean Blue';

  @override
  String get glowToggleLabel => 'Glow background';

  @override
  String get themeGreen => 'Fresh Green';

  @override
  String get themeWarm => 'Warm Orange';

  @override
  String get themePink => 'Soft Pink';

  @override
  String get plateSection => 'Plate style';

  @override
  String get plateStyleLabel => 'Plate design';

  @override
  String get plateDefaultLabel => 'Default plate';

  @override
  String get plateWarmLabel => 'Warm ceramic plate';

  @override
  String get apiSection => 'API';

  @override
  String get apiBaseUrlLabel => 'API base URL';

  @override
  String get apiBaseUrlReset => 'Clear old API and reset';

  @override
  String get apiBaseUrlResetDone => 'API base URL reset';

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
  String get estimated => 'Estimated';

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
  String get analyzeFailed => 'Unable to analyze';

  @override
  String get reestimateFailedKeepLast =>
      'Re-estimate failed. Keeping the last result.';

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
  String get mockPrefix => 'Preview';

  @override
  String get versionSection => 'Version info';

  @override
  String get versionBuild => 'Build time';

  @override
  String get versionCommit => 'Commit';

  @override
  String get versionUnavailable => 'Version info unavailable';

  @override
  String get nutritionChartLabel => 'Nutrition chart';

  @override
  String get nutritionValueLabel => 'Nutrition display';

  @override
  String get nutritionValuePercent => 'Percent';

  @override
  String get nutritionValueAmount => 'Amount';

  @override
  String get chartRadar => 'Radar';

  @override
  String get chartBars => 'Bars';

  @override
  String get chartDonut => 'Donut';

  @override
  String get dataSection => 'Data';

  @override
  String get syncSection => 'Account & Sync';

  @override
  String get syncSignedInAs => 'Signed in:';

  @override
  String get syncNotSignedIn => 'Not signed in';

  @override
  String get syncEmailLabel => 'Email';

  @override
  String get syncPasswordLabel => 'Password';

  @override
  String get syncSignIn => 'Sign in';

  @override
  String get syncSignUp => 'Sign up';

  @override
  String get syncSignUpSuccess =>
      'Verification email sent. Please confirm your email.';

  @override
  String get syncSignInSuccess => 'Signed in';

  @override
  String get syncForgotPassword => 'Forgot password';

  @override
  String get syncResetPasswordTitle => 'Reset password';

  @override
  String get syncResetPasswordHint => 'Enter your email';

  @override
  String get syncResetPasswordSent => 'Password reset email sent';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncSwitchAccount => 'Switch account';

  @override
  String get syncSwitchAccountConfirmTitle => 'Switch account';

  @override
  String get syncSwitchAccountConfirmMessage =>
      'This will clear local data and sign you out. Continue?';

  @override
  String get syncSwitchAccountConfirmAction => 'Switch';

  @override
  String get syncSwitchAccountDone =>
      'Switched account and cleared local data.';

  @override
  String get syncUpload => 'Upload sync';

  @override
  String get syncDownload => 'Download sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncInProgress => 'Syncing??;

  @override
  String get syncLastSyncLabel => 'Last sync:';

  @override
  String get syncLastResultLabel => 'Last result:';

  @override
  String get syncLastResultNone => 'No record yet';

  @override
  String get syncLastResultNoChanges => 'No changes';

  @override
  String get syncFailedItemsLabel => 'Failed items:';

  @override
  String syncFailedItemsCount(int count) {
    return '$count items';
  }

  @override
  String get syncRetryFailed => 'Retry failed items';

  @override
  String get syncSuccess => 'Sync complete';

  @override
  String get syncUpdated => 'Update complete';

  @override
  String get syncNoChanges => 'Nothing to sync right now';

  @override
  String get syncError => 'Sync failed. Please try again.';

  @override
  String get syncRequireLogin => 'Please sign in to sync';

  @override
  String get syncAuthTitleSignIn => 'Sign in';

  @override
  String get syncAuthTitleSignUp => 'Create account';

  @override
  String get exportData => 'Export data';

  @override
  String get clearData => 'Clear data';

  @override
  String get clearDataConfirm => 'Clear all data?';

  @override
  String get exportDone => 'Exported';

  @override
  String get clearDone => 'Cleared';

  @override
  String get close => 'Close';

  @override
  String get authTitle => 'Welcome to Food AI';

  @override
  String get authSubtitle => 'Sign in to unlock all features';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authToggleToSignUp => 'No account? Create one';

  @override
  String get authToggleToSignIn => 'Already have an account? Sign in';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authSignInSuccess => 'Signed in successfully';

  @override
  String get authSignUpSuccess => 'Account created';

  @override
  String get authSignUpVerify => 'Account created. Please verify your email.';

  @override
  String get authEmailNotVerified =>
      'Email not verified yet. Please confirm your email first.';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String authVerifyBody(String email) {
    return 'We sent a verification email to $email. Please check your inbox in 1?? minutes and also check spam/promotions.';
  }

  @override
  String get authResend => 'Resend verification email';

  @override
  String authResendCooldown(int seconds) {
    return 'Resend (${seconds}s)';
  }

  @override
  String get authResendSent => 'Verification email resent';

  @override
  String get authResendFailed => 'Resend failed. Please try again.';

  @override
  String get authTooManyAttempts => 'Please wait and try again.';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordRule =>
      'Password must be at least 8 characters and contain no spaces or Chinese characters';

  @override
  String get authPasswordInvalid =>
      'Password must be at least 8 characters and contain no spaces or Chinese characters';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authPasswordRequired => 'Please enter a password';

  @override
  String get authPasswordUpdated => 'Password updated';

  @override
  String get authResetPasswordAction => 'Update password';

  @override
  String get authResetLinkInvalid =>
      'Reset link is invalid or expired. Please request a new email.';

  @override
  String get authResetSent => 'Password reset email sent. Check your inbox.';

  @override
  String get authResetFailed => 'Reset failed. Please check your email.';

  @override
  String get authLoginInvalid => 'Email or password is incorrect';

  @override
  String get authEmailExists => 'Email already registered';

  @override
  String get authNetworkError => 'Connection issue. Please try again.';

  @override
  String get authSignUpFailed => 'Sign up failed';

  @override
  String get authError => 'Sign-in failed. Please try again.';

  @override
  String get trialExpiredTitle => 'Trial ended';

  @override
  String get trialExpiredBody =>
      'Your 2-day free trial has ended. Please subscribe to continue using AI analysis.';

  @override
  String get trialExpiredAction => 'View plans';

  @override
  String get signOut => 'Sign out';

  @override
  String get dietPreferenceSection => 'Diet preferences';

  @override
  String get dietTypeLabel => 'Diet type';

  @override
  String get dietNoteLabel => 'Preference notes';

  @override
  String get dietTypeNone => 'No restriction';

  @override
  String get dietTypeVegetarian => 'Lacto-ovo vegetarian';

  @override
  String get dietTypeVegan => 'Vegan';

  @override
  String get dietTypePescatarian => 'Pescatarian';

  @override
  String get dietTypeLowCarb => 'Low carb';

  @override
  String get dietTypeKeto => 'Keto';

  @override
  String get dietTypeLowFat => 'Low fat';

  @override
  String get dietTypeHighProtein => 'High protein';

  @override
  String get authNicknameRequired => 'Please enter a nickname';

  @override
  String get containerSection => 'Common container';

  @override
  String get containerTypeLabel => 'Container type';

  @override
  String get containerSizeLabel => 'Container size';

  @override
  String get containerDepthLabel => 'Bowl depth';

  @override
  String get containerDiameterLabel => 'Diameter (cm)';

  @override
  String get containerCapacityLabel => 'Capacity (ml)';

  @override
  String get containerTypeBowl => 'Bowl';

  @override
  String get containerTypePlate => 'Plate';

  @override
  String get containerTypeBox => 'Bento box';

  @override
  String get containerTypeCup => 'Cup';

  @override
  String get containerTypeUnknown => 'Not specified';

  @override
  String get containerSizeSmall => 'Small';

  @override
  String get containerSizeMedium => 'Medium';

  @override
  String get containerSizeLarge => 'Large';

  @override
  String get containerSizeStandard => 'Standard';

  @override
  String get containerSizeCustom => 'Custom';

  @override
  String get containerDepthShallow => 'Shallow';

  @override
  String get containerDepthMedium => 'Medium';

  @override
  String get containerDepthDeep => 'Deep';

  @override
  String get paywallTitle => 'Unlock full features';

  @override
  String get paywallSubtitle =>
      'AI analysis, nutrition charts, weekly/monthly summaries';

  @override
  String planMonthlyWithPrice(String price) {
    return 'Monthly $price';
  }

  @override
  String planYearlyWithPrice(String price) {
    return 'Yearly $price';
  }

  @override
  String get paywallYearlyBadge => 'Save about 30% yearly';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallDisclaimer =>
      'Subscriptions auto-renew and can be canceled in Apple ID settings. Payments are handled by Apple.';

  @override
  String get paywallStartMonthly => 'Start monthly';

  @override
  String get paywallStartYearly => 'Start yearly';

  @override
  String get paywallFeatureAiAnalysis => 'Full AI analysis';

  @override
  String get paywallFeatureNutritionAdvice => 'Calories & nutrition advice';

  @override
  String get paywallFeatureSummaries => 'Weekly/monthly summaries';

  @override
  String get paywallFeatureBestValue => 'Best value for long term';

  @override
  String get paywallUnavailableTitle => 'Subscription unavailable';

  @override
  String get paywallUnavailableBody =>
      'Unable to load App Store subscriptions. Please try again later.';

  @override
  String get webPaywallTitle => 'Unlock full features (Web test)';

  @override
  String get webPaywallTestBadge => 'Test only, no charge';

  @override
  String get webPaywallCurrentPlanMonthly => 'Current plan: Monthly (test)';

  @override
  String get webPaywallCurrentPlanYearly => 'Current plan: Yearly (test)';

  @override
  String get webPaywallCurrentPlanNone => 'Current plan: None';

  @override
  String get webPaywallTestNote =>
      'Web test: this flow does not charge real money.';

  @override
  String get webPaywallActivated => 'Test subscription enabled';

  @override
  String get webPaywallSuccessTitle => 'Test Subscription Active';

  @override
  String get webPaywallSuccessBody => 'Full features unlocked (test mode).';

  @override
  String get webPaywallSuccessCta => 'Continue';

  @override
  String get dialogOk => 'OK';

  @override
  String get syncErrorUploadFailedDetail => 'image upload failed';

  @override
  String get syncErrorSyncMetaFailedDetail => 'sync meta write failed';

  @override
  String get syncErrorPostgrestDetail => 'database request failed';

  @override
  String get syncErrorNetworkDetail => 'network connection failed';

  @override
  String syncSummaryUploadMeals(int count) {
    return 'upload meals $count';
  }

  @override
  String syncSummaryDeleteMeals(int count) {
    return 'delete meals $count';
  }

  @override
  String syncSummaryUploadCustom(int count) {
    return 'upload custom $count';
  }

  @override
  String syncSummaryDeleteCustom(int count) {
    return 'delete custom $count';
  }

  @override
  String syncSummaryUploadSettings(int count) {
    return 'upload settings $count';
  }

  @override
  String syncSummaryDownloadMeals(int count) {
    return 'download meals $count';
  }

  @override
  String syncSummaryDownloadDeletedMeals(int count) {
    return 'download deleted meals $count';
  }

  @override
  String syncSummaryDownloadCustom(int count) {
    return 'download custom $count';
  }

  @override
  String syncSummaryDownloadDeletedCustom(int count) {
    return 'download deleted custom $count';
  }

  @override
  String syncSummaryDownloadSettings(int count) {
    return 'download settings $count';
  }

  @override
  String get syncSummarySeparator => ', ';

  @override
  String get plateJapanese02 => 'Japanese plate 02';

  @override
  String get plateJapanese04 => 'Japanese plate 04';

  @override
  String get plateChina01 => 'Chinese plate 01';

  @override
  String get plateChina02 => 'Chinese plate 02';

  @override
  String get placeholderDash => '--';

  @override
  String valueWithCm(int value) {
    return '$value cm';
  }

  @override
  String valueWithKg(int value) {
    return '$value kg';
  }

  @override
  String valueWithMl(int value) {
    return '$value ml';
  }

  @override
  String get referenceObjectLabel => 'Reference object';

  @override
  String get referenceObjectNone => 'None';

  @override
  String get referenceObjectCard => 'Credit card';

  @override
  String get referenceObjectCoin10 => 'Coin (26.5 mm)';

  @override
  String get referenceObjectCoin5 => 'Coin (22 mm)';

  @override
  String get referenceObjectManual => 'Measure (cm)';

  @override
  String get referenceLengthLabel => 'Measured length (cm)';

  @override
  String get referenceLengthHint => 'Enter the measured length in cm';

  @override
  String get referenceLengthApply => 'Apply';

  @override
  String get tabChatAssistant => 'Dongdong';

  @override
  String get chatEmptyHint =>
      'Hi! I\'m Dongdong. Ask me about your meals or goals.';

  @override
  String chatEmptyHintWithName(Object name) {
    return 'Hi! I\'m $name. Ask me about your meals or goals.';
  }

  @override
  String get chatInputHint => 'Ask Dongdong...';

  @override
  String get chatLockedTitle => 'Chat unlocked with subscription';

  @override
  String get chatLockedBody =>
      'Subscribe to get personalized meal guidance and answers.';

  @override
  String get chatLockedAction => 'View subscription';

  @override
  String get chatClearTitle => 'Clear chat history?';

  @override
  String get chatClearBody =>
      'This will remove the conversation on this device.';

  @override
  String get chatClearConfirm => 'Clear';

  @override
  String get chatError => 'Chat failed. Please try again.';

  @override
  String get chatErrorAuth => 'Session expired. Please sign in again.';

  @override
  String get chatErrorQuota => 'Daily chat quota reached. Please try later.';

  @override
  String get chatErrorServer => 'Meow~ I\'m busy. Please try again soon.';

  @override
  String get chatErrorNetwork => 'Network issue. Please try again.';

  @override
  String get chatErrorReplyBase =>
      'Meow~ I\'m a little tired. Could you ask me again in a moment?';

  @override
  String get chatErrorReasonPrefix => 'Reason: ';

  @override
  String get chatErrorReasonAuth => 'Session expired or permission denied';

  @override
  String get chatErrorReasonQuota => 'Too many requests or quota reached';

  @override
  String get chatErrorReasonServer => 'Server busy or temporary error';

  @override
  String get chatErrorReasonNetwork => 'Network unstable or disconnected';

  @override
  String get chatErrorReasonUnknown => 'Unable to determine right now';

  @override
  String get chatAvatarLabel => 'Chat avatar';

  @override
  String get chatAssistantNameLabel => 'Assistant name';

  @override
  String get chatAvatarSet => 'Set';

  @override
  String get chatAvatarUnset => 'Not set';

  @override
  String get chatAvatarSheetTitle => 'Set chat avatar';

  @override
  String get chatAvatarPick => 'Choose photo';

  @override
  String get chatAvatarRemove => 'Remove photo';
}
