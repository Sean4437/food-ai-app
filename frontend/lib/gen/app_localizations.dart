import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you??l need to edit this
/// file.
///
/// First, open your project?? ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project?? Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??? AI MVP'**
  String get appTitle;

  /// No description provided for @takePhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get takePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get uploadPhoto;

  /// No description provided for @quickAdd.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????**
  String get quickAdd;

  /// No description provided for @breakfast.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get dinner;

  /// No description provided for @lateSnack.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get lateSnack;

  /// No description provided for @other.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get other;

  /// No description provided for @timeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get timeLabel;

  /// No description provided for @editTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get editTime;

  /// No description provided for @noEntries.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get noEntries;

  /// No description provided for @mealTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get mealTotal;

  /// No description provided for @mealSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get mealSummaryTitle;

  /// No description provided for @todayMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get todayMeals;

  /// No description provided for @itemsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} ??**
  String itemsCount(int count);

  /// No description provided for @captureTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get captureTitle;

  /// No description provided for @captureHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????**
  String get captureHint;

  /// No description provided for @optionalNoteLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????'**
  String get optionalNoteLabel;

  /// No description provided for @notePlaceholder.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????????????**
  String get notePlaceholder;

  /// No description provided for @recentPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get recentPhotos;

  /// No description provided for @noPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get noPhotos;

  /// No description provided for @analysisTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get analysisTitle;

  /// No description provided for @analysisEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????????'**
  String get analysisEmpty;

  /// No description provided for @foodNameLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get foodNameLabel;

  /// No description provided for @editFoodName.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get editFoodName;

  /// No description provided for @reanalyzeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reanalyzeLabel;

  /// No description provided for @addLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get addLabel;

  /// No description provided for @labelInfoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get labelInfoTitle;

  /// No description provided for @unknownFood.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get unknownFood;

  /// No description provided for @dietitianPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get dietitianPrefix;

  /// No description provided for @dietitianBalanced.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????**
  String get dietitianBalanced;

  /// No description provided for @dietitianProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????????????????????**
  String get dietitianProteinLow;

  /// No description provided for @dietitianFatHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????????**
  String get dietitianFatHigh;

  /// No description provided for @dietitianCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????**
  String get dietitianCarbHigh;

  /// No description provided for @dietitianSodiumHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????????????????**
  String get dietitianSodiumHigh;

  /// No description provided for @goalAdviceLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????????????????????????**
  String get goalAdviceLoseFat;

  /// No description provided for @goalAdviceMaintain.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????????????????????**
  String get goalAdviceMaintain;

  /// No description provided for @overallLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get overallLabel;

  /// No description provided for @calorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get calorieLabel;

  /// No description provided for @macroLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get macroLabel;

  /// No description provided for @levelLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get levelLow;

  /// No description provided for @levelMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get levelMedium;

  /// No description provided for @levelHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get levelHigh;

  /// No description provided for @statusOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @statusWarn.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get statusWarn;

  /// No description provided for @statusOver.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get statusOver;

  /// No description provided for @tagOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tagOily;

  /// No description provided for @tagProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get tagProteinOk;

  /// No description provided for @tagProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get tagProteinLow;

  /// No description provided for @tagCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get tagCarbHigh;

  /// No description provided for @tagOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get tagOk;

  /// No description provided for @nextMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????**
  String get nextMealTitle;

  /// No description provided for @nextMealSectionTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????**
  String get nextMealSectionTitle;

  /// No description provided for @nextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????**
  String get nextMealHint;

  /// No description provided for @nextSelfCookLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get nextSelfCookLabel;

  /// No description provided for @nextConvenienceLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get nextConvenienceLabel;

  /// No description provided for @nextBentoLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get nextBentoLabel;

  /// No description provided for @nextOtherLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get nextOtherLabel;

  /// No description provided for @nextSelfCookHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'???/???????????????'**
  String get nextSelfCookHint;

  /// No description provided for @nextConvenienceHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????/?????????'**
  String get nextConvenienceHint;

  /// No description provided for @nextBentoHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????'**
  String get nextBentoHint;

  /// No description provided for @nextOtherHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'???/??????/???'**
  String get nextOtherHint;

  /// No description provided for @mealItemsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get mealItemsTitle;

  /// No description provided for @optionConvenienceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get optionConvenienceTitle;

  /// No description provided for @optionConvenienceDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????/??????/?????????'**
  String get optionConvenienceDesc;

  /// No description provided for @optionBentoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get optionBentoTitle;

  /// No description provided for @optionBentoDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????????**
  String get optionBentoDesc;

  /// No description provided for @optionLightTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get optionLightTitle;

  /// No description provided for @optionLightDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????????????'**
  String get optionLightDesc;

  /// No description provided for @summaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get summaryTitle;

  /// No description provided for @summaryEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????'**
  String get summaryEmpty;

  /// No description provided for @summaryOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????**
  String get summaryOilyCarb;

  /// No description provided for @summaryOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get summaryOily;

  /// No description provided for @summaryCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get summaryCarb;

  /// No description provided for @summaryProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????**
  String get summaryProteinOk;

  /// No description provided for @summaryNeutral.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????????????????'**
  String get summaryNeutral;

  /// No description provided for @mealsCountLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get mealsCountLabel;

  /// No description provided for @mealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get mealsLabel;

  /// No description provided for @tabCapture.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabCapture;

  /// No description provided for @tabAnalysis.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabAnalysis;

  /// No description provided for @tabNext.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get tabNext;

  /// No description provided for @tabSummary.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabSummary;

  /// No description provided for @tabHome.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabHome;

  /// No description provided for @tabLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'????**
  String get tabLog;

  /// No description provided for @tabSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabSuggest;

  /// No description provided for @tabSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tabSettings;

  /// No description provided for @greetingTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Hi?????**
  String get greetingTitle;

  /// No description provided for @streakLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????? ??3 ??**
  String get streakLabel;

  /// No description provided for @aiSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ??????'**
  String get aiSuggest;

  /// No description provided for @latestMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get latestMealTitle;

  /// No description provided for @latestMealEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????**
  String get latestMealEmpty;

  /// No description provided for @homeNextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????????????**
  String get homeNextMealHint;

  /// No description provided for @logTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'????**
  String get logTitle;

  /// No description provided for @dailyCalorieRange.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get dailyCalorieRange;

  /// No description provided for @dayCardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get dayCardTitle;

  /// No description provided for @dayMealsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get dayMealsTitle;

  /// No description provided for @tomorrowAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get tomorrowAdviceTitle;

  /// No description provided for @dayCardDateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get dayCardDateLabel;

  /// No description provided for @dayCardCalorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get dayCardCalorieLabel;

  /// No description provided for @dayCardMealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get dayCardMealsLabel;

  /// No description provided for @dayCardSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get dayCardSummaryLabel;

  /// No description provided for @dayCardTomorrowLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get dayCardTomorrowLabel;
  String get finalizeDay;
  String get dishSummaryLabel;

  /// No description provided for @mealCountEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get mealCountEmpty;

  /// No description provided for @calorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get calorieUnknown;

  /// No description provided for @portionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get portionLabel;

  /// No description provided for @portionFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get portionFull;

  /// No description provided for @portionHalf.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get portionHalf;

  /// No description provided for @portionBite.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get portionBite;

  /// No description provided for @detailTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get detailTitle;

  /// No description provided for @detailAiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ??????'**
  String get detailAiLabel;

  /// No description provided for @detailAiEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get detailAiEmpty;

  /// No description provided for @detailWhyLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????'**
  String get detailWhyLabel;

  /// No description provided for @suggestTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get suggestTitle;

  String get suggestInstantHint;
  String get suggestInstantStart;
  String get suggestInstantRetake;
  String get suggestInstantSavePrompt;
  String get suggestInstantSave;
  String get suggestInstantSkipSave;
  String get suggestInstantAdviceTitle;
  String get suggestInstantCanEat;
  String get suggestInstantAvoid;
  String get suggestInstantLimit;
  String get suggestInstantMissing;
  String get suggestInstantRecentHint;

  /// No description provided for @suggestTodayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get suggestTodayLabel;

  /// No description provided for @suggestTodayHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????????????**
  String get suggestTodayHint;

  /// No description provided for @suggestTodayOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????????'**
  String get suggestTodayOilyCarb;

  /// No description provided for @suggestTodayOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????????????**
  String get suggestTodayOily;

  /// No description provided for @suggestTodayCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????????'**
  String get suggestTodayCarb;

  /// No description provided for @suggestTodayOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????OK????????**
  String get suggestTodayOk;

  /// No description provided for @logThisMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get logThisMeal;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get settingsTitle;

  /// No description provided for @profileName.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In zh_TW, this message translates to:
  /// **'xiaoming123@gmail.com'**
  String get profileEmail;

  /// No description provided for @editProfile.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get editProfile;

  /// No description provided for @planSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get planSection;

  /// No description provided for @heightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get weightLabel;

  /// No description provided for @ageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get genderLabel;

  /// No description provided for @genderUnspecified.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get genderUnspecified;

  /// No description provided for @genderMale.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get genderOther;

  /// No description provided for @bmiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// No description provided for @bmiUnderweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get bmiObese;

  /// No description provided for @goalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get goalLabel;

  /// No description provided for @goalLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get goalLoseFat;

  /// No description provided for @reminderSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reminderSection;

  /// No description provided for @reminderLunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get reminderLunch;

  /// No description provided for @reminderDinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get reminderDinner;

  /// No description provided for @subscriptionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get subscriptionSection;

  /// No description provided for @subscriptionPlan.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get subscriptionPlan;

  /// No description provided for @planMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????? \$199/??**
  String get planMonthly;

  /// No description provided for @languageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get languageLabel;

  /// No description provided for @langZh.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get edit;

  /// No description provided for @editDaySummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get editDaySummaryTitle;

  /// No description provided for @editMealAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????????**
  String get editMealAdviceTitle;

  /// No description provided for @goalMaintain.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get goalMaintain;

  /// No description provided for @planSpeedLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get planSpeedLabel;

  /// No description provided for @planSpeedStable.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get planSpeedStable;

  /// No description provided for @planSpeedGentle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get planSpeedGentle;

  /// No description provided for @reminderLunchTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get reminderLunchTime;

  /// No description provided for @reminderDinnerTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????'**
  String get reminderDinnerTime;

  /// No description provided for @pickFromCamera.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get pickFromCamera;

  /// No description provided for @pickFromGallery.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get pickFromGallery;

  /// No description provided for @addMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get addMeal;

  /// No description provided for @noMealPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????'**
  String get noMealPrompt;

  /// No description provided for @layoutThemeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get layoutThemeLabel;

  /// No description provided for @themeClean.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get themeClean;

  /// No description provided for @themeWarm.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get themeWarm;

  /// No description provided for @plateSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get plateSection;

  /// No description provided for @plateStyleLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get plateStyleLabel;

  /// No description provided for @plateDefaultLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get plateDefaultLabel;

  /// No description provided for @plateWarmLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get plateWarmLabel;

  /// No description provided for @apiSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'API ???'**
  String get apiSection;

  /// No description provided for @apiBaseUrlLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'API ???'**
  String get apiBaseUrlLabel;

  /// No description provided for @delete.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????????**
  String get deleteConfirm;

  /// No description provided for @logSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????'**
  String get logSuccess;

  /// No description provided for @viewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get viewLog;

  /// No description provided for @calories.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get calories;

  /// No description provided for @estimated.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get estimated;

  /// No description provided for @protein.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get fat;

  /// No description provided for @sodium.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get sodium;

  /// No description provided for @tier.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get tier;

  /// No description provided for @analyzeFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get analyzeFailed;

  /// No description provided for @costEstimateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get costEstimateLabel;

  /// No description provided for @usageSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ???'**
  String get usageSection;

  /// No description provided for @usageTotalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get usageTotalLabel;

  /// No description provided for @usageViewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'???????**
  String get usageViewLog;

  /// No description provided for @usageEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????????**
  String get usageEmpty;

  /// No description provided for @usageLoading.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????..'**
  String get usageLoading;

  /// No description provided for @mockPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get mockPrefix;

  /// No description provided for @versionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get versionSection;

  /// No description provided for @versionBuild.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get versionBuild;

  /// No description provided for @versionCommit.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get versionCommit;

  /// No description provided for @versionUnavailable.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????????'**
  String get versionUnavailable;
  /// No description provided for @nutritionChartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????'**
  String get nutritionChartLabel;

  /// No description provided for @chartRadar.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get chartRadar;

  /// No description provided for @chartBars.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get chartBars;

  /// No description provided for @chartDonut.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get chartDonut;

  /// No description provided for @dataSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get exportData;

  /// No description provided for @clearData.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get clearData;

  /// No description provided for @clearDataConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????????????????**
  String get clearDataConfirm;

  /// No description provided for @exportDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get exportDone;

  /// No description provided for @clearDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????**
  String get clearDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

