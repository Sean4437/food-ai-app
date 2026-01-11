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

  /// No description provided for @brunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'?蹓潘??'**
  String get brunch;

  /// No description provided for @lunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剝?'**
  String get lunch;

  /// No description provided for @afternoonTea.
  ///
  /// In zh_TW, this message translates to:
  /// **'?謚渡??'**
  String get afternoonTea;

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

  /// No description provided for @mealSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?祈???'**
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

  /// No description provided for @addLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'鋆?璅內'**
  String get addLabel;

  /// No description provided for @labelInfoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'璅內鞈?'**
  String get labelInfoTitle;

  /// No description provided for @unknownFood.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芸??暺?**
  String get unknownFood;

  /// No description provided for @dietitianPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降嚗?**
  String get dietitianPrefix;

  /// No description provided for @dietitianBalanced.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湧??﹛嚗雁??胯?**
  String get dietitianBalanced;

  /// No description provided for @dietitianProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈芸?雿?撱箄降鋆?擳???**
  String get dietitianProteinLow;

  /// No description provided for @dietitianFatHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘝寡???嚗?銝擗?瘛∪?瘝嫘?**
  String get dietitianFatHigh;

  /// No description provided for @dietitianCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣單偌??嚗蜓憌???**
  String get dietitianCarbHigh;

  /// No description provided for @dietitianSodiumHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'???擃?皜?皝臬???撌亙???**
  String get dietitianSodiumHigh;

  /// No description provided for @goalAdviceLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞交???格?嚗?銝擗誑?鞈芾??祈??箔蜓??**
  String get goalAdviceLoseFat;

  /// No description provided for @goalAdviceMaintain.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞亦雁?銝鳴?瘜冽?隞賡???銵～?**
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
  /// **'銝?擗遣霅唳獐??**
  String get nextMealTitle;

  /// No description provided for @nextMealSectionTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?擗遣霅唳獐??**
  String get nextMealSectionTitle;

  /// No description provided for @noLateSnackSelfCook.
  ///
  /// In zh_TW, this message translates to:
  /// **'不建議消夜；若想吃，清湯蔬菜小份'**
  String get noLateSnackSelfCook;

  /// No description provided for @noLateSnackConvenience.
  ///
  /// In zh_TW, this message translates to:
  /// **'不建議消夜；若想吃，無糖豆漿或小份沙拉'**
  String get noLateSnackConvenience;

  /// No description provided for @noLateSnackBento.
  ///
  /// In zh_TW, this message translates to:
  /// **'不建議消夜；若想吃，半份蔬菜便當'**
  String get noLateSnackBento;

  /// No description provided for @noLateSnackOther.
  ///
  /// In zh_TW, this message translates to:
  /// **'不建議消夜；若想吃，少量水果即可'**
  String get noLateSnackOther;

  /// No description provided for @nextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?訾????嫣噶?撘停憟?**
  String get nextMealHint;

  /// No description provided for @nextSelfCookLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芰'**
  String get nextSelfCookLabel;

  /// No description provided for @nextConvenienceLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘踹摨?**
  String get nextConvenienceLabel;

  /// No description provided for @nextBentoLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘輻'**
  String get nextBentoLabel;

  /// No description provided for @nextOtherLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?嗡?'**
  String get nextOtherLabel;

  /// No description provided for @nextSelfCookHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜/瘞渡嚗??撠硃撠'**
  String get nextSelfCookHint;

  /// No description provided for @nextConvenienceHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?嗉????∠?鞊撚/瘝?嚗??貊'**
  String get nextConvenienceHint;

  /// No description provided for @nextBentoHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?ㄞ?????遠'**
  String get nextBentoHint;

  /// No description provided for @nextOtherHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘞湔?/?∠??芣/皜僖'**
  String get nextOtherHint;

  /// No description provided for @mealItemsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'餈??祇?'**
  String get mealItemsTitle;

  /// No description provided for @mealTimeSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'???筑???'**
  String get mealTimeSection;

  /// No description provided for @breakfastStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???謍??'**
  String get breakfastStartLabel;

  /// No description provided for @breakfastEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???謍??'**
  String get breakfastEndLabel;

  /// No description provided for @brunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?蹓潘??謍??'**
  String get brunchStartLabel;

  /// No description provided for @brunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?蹓潘??謍??'**
  String get brunchEndLabel;

  /// No description provided for @lunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???謍??'**
  String get lunchStartLabel;

  /// No description provided for @lunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???謍??'**
  String get lunchEndLabel;

  /// No description provided for @afternoonTeaStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?謚渡??謍??'**
  String get afternoonTeaStartLabel;

  /// No description provided for @afternoonTeaEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?謚渡??謍??'**
  String get afternoonTeaEndLabel;

  /// No description provided for @dinnerStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?謍?謍??'**
  String get dinnerStartLabel;

  /// No description provided for @dinnerEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?謍?謍??'**
  String get dinnerEndLabel;

  /// No description provided for @lateSnackStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?剁??謍??'**
  String get lateSnackStartLabel;

  /// No description provided for @lateSnackEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?剁??謍??'**
  String get lateSnackEndLabel;

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
  /// **'?單?撱箄降'**
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

  /// No description provided for @dayCardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘥??'**
  String get dayCardTitle;

  /// No description provided for @dayMealsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'餈??祆擗活'**
  String get dayMealsTitle;

  /// No description provided for @tomorrowAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?予撱箄降'**
  String get tomorrowAdviceTitle;

  /// No description provided for @dayCardDateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?交?嚗?**
  String get dayCardDateLabel;

  /// No description provided for @dayCardCalorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?梢???'**
  String get dayCardCalorieLabel;

  /// No description provided for @dayCardMealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??擗嚗?**
  String get dayCardMealsLabel;

  /// No description provided for @dayCardSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予憌脤?蝮賜?'**
  String get dayCardSummaryLabel;

  /// No description provided for @dayCardTomorrowLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?予撱箄降'**
  String get dayCardTomorrowLabel;

  /// No description provided for @summaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠 {time} 蝮賜?'**
  String summaryPendingAt(Object time);

  /// No description provided for @weekSummaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠 {day} {time} 蝮賜?'**
  String weekSummaryPendingAt(Object day, Object time);

  /// No description provided for @finalizeDay.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝯?隞予'**
  String get finalizeDay;

  /// No description provided for @dishSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?祇???'**
  String get dishSummaryLabel;

  /// No description provided for @mealCountEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠??擗活'**
  String get mealCountEmpty;

  /// No description provided for @calorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠隡啗?'**
  String get calorieUnknown;

  /// No description provided for @portionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞賡?'**
  String get portionLabel;

  /// No description provided for @portionFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'?典?'**
  String get portionFull;

  /// No description provided for @portionHalf.
  ///
  /// In zh_TW, this message translates to:
  /// **'????**
  String get portionHalf;

  /// No description provided for @portionBite.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芸?撟曉'**
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
  /// **'?單?撱箄降'**
  String get suggestTitle;

  /// No description provided for @suggestInstantHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'??蝡??嚗策雿??獐??**
  String get suggestInstantHint;

  /// No description provided for @suggestInstantStart.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get suggestInstantStart;

  /// No description provided for @suggestInstantRetake.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get suggestInstantRetake;

  /// No description provided for @suggestInstantSavePrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'閬摮???'**
  String get suggestInstantSavePrompt;

  /// No description provided for @suggestInstantSave.
  ///
  /// In zh_TW, this message translates to:
  /// **'?脣?'**
  String get suggestInstantSave;

  /// No description provided for @suggestInstantSkipSave.
  ///
  /// In zh_TW, this message translates to:
  /// **'???脣?'**
  String get suggestInstantSkipSave;

  /// No description provided for @suggestInstantAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'???獐??頛末'**
  String get suggestInstantAdviceTitle;

  /// No description provided for @suggestInstantCanEat.
  ///
  /// In zh_TW, this message translates to:
  /// **'?臭誑??**
  String get suggestInstantCanEat;

  /// No description provided for @suggestInstantAvoid.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅啣?'**
  String get suggestInstantAvoid;

  /// No description provided for @suggestInstantLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降隞賡?銝?'**
  String get suggestInstantLimit;

  /// No description provided for @suggestInstantMissing.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠??????**
  String get suggestInstantMissing;

  /// No description provided for @suggestInstantRecentHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降撌脣???餈?7 憭抵?銝?擗?**
  String get suggestInstantRecentHint;

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

  /// No description provided for @ageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撟湧翩'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?批'**
  String get genderLabel;

  /// No description provided for @genderUnspecified.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?摰?**
  String get genderUnspecified;

  /// No description provided for @genderMale.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh_TW, this message translates to:
  /// **'憟?**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In zh_TW, this message translates to:
  /// **'?嗡?'**
  String get genderOther;

  /// No description provided for @bmiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// No description provided for @bmiUnderweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇?虜'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
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
  /// **'蝺刻摩'**
  String get edit;

  /// No description provided for @editDaySummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝺刻摩隞??'**
  String get editDaySummaryTitle;

  /// No description provided for @editMealAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝺刻摩銝?擗遣霅?**
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

  /// No description provided for @adviceStyleSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降憸冽'**
  String get adviceStyleSection;

  /// No description provided for @toneLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降隤除'**
  String get toneLabel;

  /// No description provided for @personaLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'閫閬?'**
  String get personaLabel;

  /// No description provided for @toneGentle.
  ///
  /// In zh_TW, this message translates to:
  /// **'皞怠?'**
  String get toneGentle;

  /// No description provided for @toneDirect.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湔'**
  String get toneDirect;

  /// No description provided for @toneEncouraging.
  ///
  /// In zh_TW, this message translates to:
  /// **'瞈??**
  String get toneEncouraging;

  /// No description provided for @toneBullet.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜?璇?'**
  String get toneBullet;

  /// No description provided for @toneStrict.
  ///
  /// In zh_TW, this message translates to:
  /// **'嚴厲'**
  String get toneStrict;

  /// No description provided for @personaNutritionist.
  ///
  /// In zh_TW, this message translates to:
  /// **'??撣?**
  String get personaNutritionist;

  /// No description provided for @personaCoach.
  ///
  /// In zh_TW, this message translates to:
  /// **'憭??毀'**
  String get personaCoach;

  /// No description provided for @personaFriend.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get personaFriend;

  /// No description provided for @personaSystem.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝎曄陛蝟餌絞'**
  String get personaSystem;

  /// No description provided for @summarySettingsSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝮賜?閮剖?'**
  String get summarySettingsSection;

  /// No description provided for @summaryTimeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘥蝮賜???'**
  String get summaryTimeLabel;

  /// No description provided for @weeklySummaryDayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘥梁蜇蝯'**
  String get weeklySummaryDayLabel;

  /// No description provided for @weekSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?梁蜇蝯?**
  String get weekSummaryTitle;

  /// No description provided for @nextWeekAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝勗遣霅?**
  String get nextWeekAdviceTitle;

  /// No description provided for @weekdayMon.
  ///
  /// In zh_TW, this message translates to:
  /// **'?曹?'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh_TW, this message translates to:
  /// **'?曹?'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh_TW, this message translates to:
  /// **'?曹?'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh_TW, this message translates to:
  /// **'?勗?'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh_TW, this message translates to:
  /// **'?曹?'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh_TW, this message translates to:
  /// **'?勗'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh_TW, this message translates to:
  /// **'?望'**
  String get weekdaySun;

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

  /// No description provided for @activityLevelLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?身瘣餃???**
  String get activityLevelLabel;

  String get activityLabel;

  /// No description provided for @activityCardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞瘣餃???**
  String get activityCardTitle;

  /// No description provided for @targetCalorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠隡啗?'**
  String get targetCalorieUnknown;

  /// No description provided for @activitySedentary.
  ///
  /// In zh_TW, this message translates to:
  /// **'銋?'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛?'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剖漲'**
  String get activityModerate;

  /// No description provided for @activityHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'擃?**
  String get activityHigh;

  /// No description provided for @exerciseLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get exerciseLabel;

  /// No description provided for @exerciseMinutesLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get exerciseMinutesLabel;

  /// No description provided for @exerciseMinutesUnit.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get exerciseMinutesUnit;

  /// No description provided for @exerciseMinutesHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛詨????**
  String get exerciseMinutesHint;

  /// No description provided for @exerciseCaloriesLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??瘨?**
  String get exerciseCaloriesLabel;

  /// No description provided for @exerciseNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get exerciseNone;

  String get exerciseNoExercise;

  /// No description provided for @exerciseWalking.
  ///
  /// In zh_TW, this message translates to:
  /// **'敹怨粥'**
  String get exerciseWalking;

  /// No description provided for @exerciseJogging.
  ///
  /// In zh_TW, this message translates to:
  /// **'?Ｚ?'**
  String get exerciseJogging;

  /// No description provided for @exerciseCycling.
  ///
  /// In zh_TW, this message translates to:
  /// **'?株?'**
  String get exerciseCycling;

  /// No description provided for @exerciseSwimming.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜豢陶'**
  String get exerciseSwimming;

  /// No description provided for @exerciseStrength.
  ///
  /// In zh_TW, this message translates to:
  /// **'??閮毀'**
  String get exerciseStrength;

  /// No description provided for @exerciseYoga.
  ///
  /// In zh_TW, this message translates to:
  /// **'?播'**
  String get exerciseYoga;

  /// No description provided for @exerciseHiit.
  ///
  /// In zh_TW, this message translates to:
  /// **'??閮毀'**
  String get exerciseHiit;

  /// No description provided for @exerciseBasketball.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝐?'**
  String get exerciseBasketball;

  /// No description provided for @exerciseHiking.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃控'**
  String get exerciseHiking;

  /// No description provided for @deltaUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠隡啗?'**
  String get deltaUnknown;

  /// No description provided for @deltaOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亥??格?'**
  String get deltaOk;

  /// No description provided for @deltaSurplus.
  ///
  /// In zh_TW, this message translates to:
  /// **'頞 {kcal} kcal'**
  String deltaSurplus(int kcal);

  /// No description provided for @deltaDeficit.
  ///
  /// In zh_TW, this message translates to:
  /// **'韏文? {kcal} kcal'**
  String deltaDeficit(int kcal);

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

  /// No description provided for @textSizeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'摮?憭批?'**
  String get textSizeLabel;

  /// No description provided for @textSizeSmall.
  ///
  /// In zh_TW, this message translates to:
  /// **'璅?'**
  String get textSizeSmall;

  /// No description provided for @textSizeMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'?之'**
  String get textSizeMedium;

  /// No description provided for @textSizeLarge.
  ///
  /// In zh_TW, this message translates to:
  /// **'?孵之'**
  String get textSizeLarge;

  /// No description provided for @themeClean.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜??**
  String get themeClean;

  /// No description provided for @themeWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**

    ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get themeWarm;

  String get themeGreen;

  String get glowToggleLabel;

  /// No description provided for @plateSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'?文?璅??'**
  String get plateSection;

  /// No description provided for @plateStyleLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?文?甈曉?'**
  String get plateStyleLabel;

  /// No description provided for @plateDefaultLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?身?瑞'**
  String get plateDefaultLabel;

  /// No description provided for @plateWarmLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??嗥??**
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

  /// No description provided for @versionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈?'**
  String get versionSection;

  /// No description provided for @versionBuild.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湔??'**
  String get versionBuild;

  /// No description provided for @versionCommit.
  ///
  /// In zh_TW, this message translates to:
  /// **'?隞?Ⅳ'**
  String get versionCommit;

  /// No description provided for @versionUnavailable.
  ///
  /// In zh_TW, this message translates to:
  /// **'?⊥????鞈?'**
  String get versionUnavailable;

  /// No description provided for @nutritionChartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???”'**
  String get nutritionChartLabel;

  /// No description provided for @chartRadar.
  ///
  /// In zh_TW, this message translates to:
  /// **'?琿???**
  String get chartRadar;

  /// No description provided for @chartBars.
  ///
  /// In zh_TW, this message translates to:
  /// **'璇???**
  String get chartBars;

  /// No description provided for @chartDonut.
  ///
  /// In zh_TW, this message translates to:
  /// **'???**
  String get chartDonut;

  /// No description provided for @dataSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'鞈?蝞∠?'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In zh_TW, this message translates to:
  /// **'?臬鞈?'**
  String get exportData;

  /// No description provided for @clearData.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜鞈?'**
  String get clearData;

  /// No description provided for @clearDataConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣箏?閬??斗?????嚗?**
  String get clearDataConfirm;

  /// No description provided for @exportDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣??**
  String get exportDone;

  /// No description provided for @clearDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脫???**
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
