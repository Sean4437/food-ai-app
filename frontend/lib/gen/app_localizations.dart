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
/// To configure the locales supported by your app, you?l need to edit this
/// file.
///
/// First, open your project? ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project? Runner folder.
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
  /// **'憌脤? AI MVP'**
  String get appTitle;

  /// No description provided for @takePhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'?蝝??**
  String get takePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?抒?'**
  String get uploadPhoto;

  /// No description provided for @quickAdd.
  ///
  /// In zh_TW, this message translates to:
  /// **'敹恍憓??芸???嚗?**
  String get quickAdd;

  /// No description provided for @breakfast.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拚?'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剝?'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get dinner;

  /// No description provided for @lateSnack.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘨?'**
  String get lateSnack;

  /// No description provided for @other.
  ///
  /// In zh_TW, this message translates to:
  /// **'?嗡?'**
  String get other;

  /// No description provided for @timeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get timeLabel;

  /// No description provided for @editTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'靽格??'**
  String get editTime;

  /// No description provided for @noEntries.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠蝝??**
  String get noEntries;

  /// No description provided for @mealTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'?祇?隡啗??梢?'**
  String get mealTotal;

  String get mealSummaryTitle;

  /// No description provided for @todayMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞擗?'**
  String get todayMeals;

  /// No description provided for @itemsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 蝑?**
  String itemsCount(int count);

  /// No description provided for @captureTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?蝝??**
  String get captureTitle;

  /// No description provided for @captureHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'??雿迤?典???暺??**
  String get captureHint;

  /// No description provided for @optionalNoteLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'鋆?隤芣?嚗?賂?'**
  String get optionalNoteLabel;

  /// No description provided for @notePlaceholder.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘?嚗?????葆韏?**
  String get notePlaceholder;

  /// No description provided for @recentPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餈??**
  String get recentPhotos;

  /// No description provided for @noPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠?啣??抒?'**
  String get noPhotos;

  /// No description provided for @analysisTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'擗???'**
  String get analysisTitle;

  /// No description provided for @analysisEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'????暺?????銝撘萄'**
  String get analysisEmpty;

  /// No description provided for @foodNameLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'憌?迂'**
  String get foodNameLabel;

  /// No description provided for @editFoodName.
  ///
  /// In zh_TW, this message translates to:
  /// **'靽格憌?迂'**
  String get editFoodName;

  /// No description provided for @reanalyzeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get reanalyzeLabel;

  String get unknownFood;

  String get dietitianPrefix;

  String get dietitianBalanced;

  String get dietitianProteinLow;

  String get dietitianFatHigh;

  String get dietitianCarbHigh;

  String get dietitianSodiumHigh;
  String get goalAdviceLoseFat;
  String get goalAdviceMaintain;

  /// No description provided for @overallLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湧??斗'**
  String get overallLabel;

  /// No description provided for @calorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梢????**
  String get calorieLabel;

  /// No description provided for @macroLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝之??'**
  String get macroLabel;

  /// No description provided for @levelLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'雿?**
  String get levelLow;

  /// No description provided for @levelMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?**
  String get levelMedium;

  /// No description provided for @levelHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'擃?**
  String get levelHigh;

  /// No description provided for @statusOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @statusWarn.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get statusWarn;

  /// No description provided for @statusOver.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get statusOver;

  /// No description provided for @tagOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'?硃'**
  String get tagOily;

  /// No description provided for @tagProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈芾雲'**
  String get tagProteinOk;

  /// No description provided for @tagProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈芯?頞?**
  String get tagProteinLow;

  /// No description provided for @tagCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣單偌??'**
  String get tagCarbHigh;

  /// No description provided for @tagOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get tagOk;

  /// No description provided for @nextMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?擗獐鋆?頛末'**
  String get nextMealTitle;

  /// No description provided for @nextMealSectionTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'下一餐建議怎麼吃'**
  String get nextMealSectionTitle;

  /// No description provided for @nextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?訾????嫣噶?撘停憟?**
  String get nextMealHint;

  /// No description provided for @nextSelfCookLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'自煮'**
  String get nextSelfCookLabel;

  /// No description provided for @nextConvenienceLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'便利店'**
  String get nextConvenienceLabel;

  /// No description provided for @nextBentoLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'便當'**
  String get nextBentoLabel;

  /// No description provided for @nextOtherLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'其他'**
  String get nextOtherLabel;

  /// No description provided for @nextSelfCookHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'清蒸/水煮＋蔬菜，少油少醬'**
  String get nextSelfCookHint;

  /// No description provided for @nextConvenienceHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'茶葉蛋/無糖豆漿/沙拉，少炸物'**
  String get nextConvenienceHint;

  /// No description provided for @nextBentoHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'半飯、多菜、優先烤或滷'**
  String get nextBentoHint;

  /// No description provided for @nextOtherHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'水果/無糖優格/清湯'**
  String get nextOtherHint;

  String get mealItemsTitle;

  /// No description provided for @optionConvenienceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘踹??'**
  String get optionConvenienceTitle;

  /// No description provided for @optionConvenienceDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'?貉??/?∠?鞊撚/瘝?嚗??貊'**
  String get optionConvenienceDesc;

  /// No description provided for @optionBentoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘輻摨?**
  String get optionBentoTitle;

  /// No description provided for @optionBentoDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'?ㄞ???祈????斗?皛?**
  String get optionBentoDesc;

  /// No description provided for @optionLightTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜楚?豢?'**
  String get optionLightTitle;

  /// No description provided for @optionLightDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜僖??柴??祆?'**
  String get optionLightDesc;

  /// No description provided for @summaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞??'**
  String get summaryTitle;

  /// No description provided for @summaryEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予撠閮?擗?'**
  String get summaryEmpty;

  /// No description provided for @summaryOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予憭??硃?４瘞游?憭?**
  String get summaryOilyCarb;

  /// No description provided for @summaryOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予憭??硃'**
  String get summaryOily;

  /// No description provided for @summaryCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予蝣單偌??'**
  String get summaryCarb;

  /// No description provided for @summaryProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈芸??荔?閮?鋆??**
  String get summaryProteinOk;

  /// No description provided for @summaryNeutral.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?湧????荔?蝬剜??喳'**
  String get summaryNeutral;

  /// No description provided for @mealsCountLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰???**
  String get mealsCountLabel;

  /// No description provided for @mealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'擗?**
  String get mealsLabel;

  /// No description provided for @tabCapture.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get tabCapture;

  /// No description provided for @tabAnalysis.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get tabAnalysis;

  /// No description provided for @tabNext.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?擗?**
  String get tabNext;

  /// No description provided for @tabSummary.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get tabSummary;

  /// No description provided for @tabHome.
  ///
  /// In zh_TW, this message translates to:
  /// **'擐?'**
  String get tabHome;

  /// No description provided for @tabLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝝??**
  String get tabLog;

  /// No description provided for @tabSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降'**
  String get tabSuggest;

  /// No description provided for @tabSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮剖?'**
  String get tabSettings;

  /// No description provided for @greetingTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Hi嚗???**
  String get greetingTitle;

  /// No description provided for @streakLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?梢??? 蝚?3 憭?**
  String get streakLabel;

  /// No description provided for @aiSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 憌脤?撱箄降'**
  String get aiSuggest;

  /// No description provided for @latestMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'????擗?'**
  String get latestMealTitle;

  /// No description provided for @latestMealEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠??暺???**
  String get latestMealEmpty;

  /// No description provided for @homeNextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'暺脣遣霅圈?嚗銝???嫣噶?獢?**
  String get homeNextMealHint;

  /// No description provided for @logTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝝??**
  String get logTitle;

  /// No description provided for @dailyCalorieRange.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?梢???'**
  String get dailyCalorieRange;

  String get dayCardTitle;

  String get dayMealsTitle;

  String get tomorrowAdviceTitle;

  /// No description provided for @dayCardDateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'日期：'**
  String get dayCardDateLabel;

  /// No description provided for @dayCardCalorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日熱量攝取'**
  String get dayCardCalorieLabel;

  /// No description provided for @dayCardMealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'分析餐數：'**
  String get dayCardMealsLabel;

  /// No description provided for @dayCardSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天飲食總結'**
  String get dayCardSummaryLabel;

  /// No description provided for @dayCardTomorrowLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'明天建議'**
  String get dayCardTomorrowLabel;

  /// No description provided for @mealCountEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未分析餐次'**
  String get mealCountEmpty;

  /// No description provided for @calorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠隡啗?'**
  String get calorieUnknown;

  String get portionLabel;

  String get portionFull;

  String get portionHalf;

  String get portionBite;

  /// No description provided for @detailTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閰喟敦蝝??**
  String get detailTitle;

  /// No description provided for @detailAiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ?斗隤芣?'**
  String get detailAiLabel;

  /// No description provided for @detailAiEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠??鞈?'**
  String get detailAiEmpty;

  /// No description provided for @detailWhyLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?箔?暻潮見?斗'**
  String get detailWhyLabel;

  /// No description provided for @suggestTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'憭?撱箄降'**
  String get suggestTitle;

  /// No description provided for @suggestTodayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?湧??斗'**
  String get suggestTodayLabel;

  /// No description provided for @suggestTodayHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予瘝寡???嚗遣霅唬?銝擗?瘛∩?暺?**
  String get suggestTodayHint;

  /// No description provided for @suggestTodayOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?硃?４瘞港???'**
  String get suggestTodayOilyCarb;

  /// No description provided for @suggestTodayOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?硃嚗?銝擗?瘛∩?暺?**
  String get suggestTodayOily;

  /// No description provided for @suggestTodayCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予蝣單偌??嚗?銝擗?瞉梁?'**
  String get suggestTodayCarb;

  /// No description provided for @suggestTodayOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予???OK嚗??停憟?**
  String get suggestTodayOk;

  /// No description provided for @logThisMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮???'**
  String get logThisMeal;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮剖?'**
  String get settingsTitle;

  /// No description provided for @profileName.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠?'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In zh_TW, this message translates to:
  /// **'xiaoming123@gmail.com'**
  String get profileEmail;

  /// No description provided for @editProfile.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝺刻摩?犖鞈?'**
  String get editProfile;

  /// No description provided for @planSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮閮剖?'**
  String get planSection;

  /// No description provided for @heightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'頨恍?'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'擃?'**
  String get weightLabel;
  String get ageLabel;
  String get bmiLabel;
  String get bmiUnderweight;
  String get bmiNormal;
  String get bmiOverweight;
  String get bmiObese;

  /// No description provided for @goalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?格?'**
  String get goalLabel;

  /// No description provided for @goalLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜?????**
  String get goalLoseFat;

  /// No description provided for @reminderSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'??閮剖?'**
  String get reminderSection;

  /// No description provided for @reminderLunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reminderLunch;

  /// No description provided for @reminderDinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reminderDinner;

  /// No description provided for @subscriptionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮?隞?**
  String get subscriptionSection;

  /// No description provided for @subscriptionPlan.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀??寞?'**
  String get subscriptionPlan;

  /// No description provided for @planMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜??冽 \$199/??**
  String get planMonthly;

  /// No description provided for @languageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湔?隤?'**
  String get languageLabel;

  /// No description provided for @langZh.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝜?銝剜?'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh_TW, this message translates to:
  /// **'?脣?'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯'**
  String get edit;

  /// No description provided for @editDaySummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯今日摘要'**
  String get editDaySummaryTitle;

  /// No description provided for @editMealAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯下一餐建議'**
  String get editMealAdviceTitle;

  /// No description provided for @goalMaintain.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝬剜?擃?'**
  String get goalMaintain;

  /// No description provided for @planSpeedLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜??漲'**
  String get planSpeedLabel;

  /// No description provided for @planSpeedStable.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝛拙?'**
  String get planSpeedStable;

  /// No description provided for @planSpeedGentle.
  ///
  /// In zh_TW, this message translates to:
  /// **'靽?'**
  String get planSpeedGentle;

  /// No description provided for @reminderLunchTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reminderLunchTime;

  /// No description provided for @reminderDinnerTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????'**
  String get reminderDinnerTime;

  /// No description provided for @pickFromCamera.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get pickFromCamera;

  /// No description provided for @pickFromGallery.
  ///
  /// In zh_TW, this message translates to:
  /// **'敺蝪輸??**
  String get pickFromGallery;

  /// No description provided for @addMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'?啣?'**
  String get addMeal;

  /// No description provided for @noMealPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠蝝????撘萎??臭誑'**
  String get noMealPrompt;

  /// No description provided for @layoutThemeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝駁?????**
  String get layoutThemeLabel;

  /// No description provided for @themeClean.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜??**
  String get themeClean;

  /// No description provided for @themeWarm.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get themeWarm;

  /// No description provided for @plateSection.
  String get plateSection;

  /// No description provided for @plateStyleLabel.
  String get plateStyleLabel;

  /// No description provided for @plateDefaultLabel.
  String get plateDefaultLabel;

  /// No description provided for @plateWarmLabel.
  String get plateWarmLabel;

  /// No description provided for @apiSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'API ???'**
  String get apiSection;

  /// No description provided for @apiBaseUrlLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'API 雿?'**
  String get apiBaseUrlLabel;

  /// No description provided for @delete.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芷'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣箏?閬?斗迨蝝??嚗?**
  String get deleteConfirm;

  /// No description provided for @logSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰???'**
  String get logSuccess;

  /// No description provided for @viewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亦?蝝??**
  String get viewLog;

  /// No description provided for @calories.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梢?'**
  String get calories;

  /// No description provided for @estimated.
  ///
  /// In zh_TW, this message translates to:
  /// **'隡啗?'**
  String get estimated;

  /// No description provided for @protein.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈?**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣單偌'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get fat;

  /// No description provided for @sodium.
  ///
  /// In zh_TW, this message translates to:
  /// **'???**
  String get sodium;

  /// No description provided for @tier.
  ///
  /// In zh_TW, this message translates to:
  /// **'撅斤?'**
  String get tier;

  /// No description provided for @analyzeFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'??憭望?'**
  String get analyzeFailed;

  /// No description provided for @costEstimateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隡啁??梯祥'**
  String get costEstimateLabel;

  /// No description provided for @usageSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ?梯祥'**
  String get usageSection;

  /// No description provided for @usageTotalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝝航??梯祥'**
  String get usageTotalLabel;

  /// No description provided for @usageViewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亦?蝝??**
  String get usageViewLog;

  /// No description provided for @usageEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠?梯祥蝝??**
  String get usageEmpty;

  /// No description provided for @usageLoading.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛銝?..'**
  String get usageLoading;

    /// No description provided for @mockPrefix.
    ///
    /// In zh_TW, this message translates to:
    /// **'??'**
  String get mockPrefix;

  String get versionSection;

  String get versionBuild;

  String get versionCommit;

  String get versionUnavailable;

  String get dataSection;

  String get exportData;

  String get clearData;

  String get clearDataConfirm;

  String get exportDone;

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

