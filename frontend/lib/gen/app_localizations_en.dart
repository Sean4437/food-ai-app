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
  String get analysisEmpty => 'No analysis yet — take a photo to start';

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
  String get summaryTitle => 'Today’s summary';

  @override
  String get summaryEmpty => 'No meals recorded today yet';

  @override
  String get summaryOilyCarb => 'A bit oily and carb-heavy today';

  @override
  String get summaryOily => 'A bit oily today';

  @override
  String get summaryCarb => 'Carb-heavy today';

  @override
  String get summaryProteinOk => 'Protein looks OK — add some veggies';

  @override
  String get summaryNeutral => 'You’re doing well today, keep it up';

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
    return 'Hi $name, you’ve got this';
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
  String get dayCardCalorieLabel => 'Today calorie range';

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
  String get suggestInstantAdviceTitle => 'How to eat this meal better';

  @override
  String get suggestInstantCanEat => 'Good choices';

  @override
  String get suggestInstantAvoid => 'Avoid';

  @override
  String get suggestInstantLimit => 'Portion limit';

  @override
  String get suggestInstantMissing => 'No analysis yet';

  @override
  String get suggestInstantNonFood =>
      'This doesn\'t look like food. Please retake. If you\'re not planning to eat now, feel free to use the app when you\'re hungry.';

  @override
  String get suggestInstantAdjustedHint => 'Adjusted for portion size';

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
      'Fat is a bit high today — keep the next meal lighter';

  @override
  String get suggestTodayOilyCarb => 'Oily and carb-heavy today';

  @override
  String get suggestTodayOily => 'A bit oily today, go lighter next meal';

  @override
  String get suggestTodayCarb => 'Carbs are high today, go lighter on starch';

  @override
  String get suggestTodayOk => 'You’re doing well today — keep it up';

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
  String suggestExerciseHint(String exercise, int minutes) {
    return 'Try $exercise for about $minutes min';
  }

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
  String get syncUpload => 'Upload sync';

  @override
  String get syncDownload => 'Download sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncInProgress => 'Syncing…';

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
    return 'We sent a verification email to $email. Please check your inbox in 1–3 minutes and also check spam/promotions.';
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
}
