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
  /// **'?拙?擗?**
  String get brunch;

  /// No description provided for @lunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剝?'**
  String get lunch;

  /// No description provided for @afternoonTea.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝???**
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
  /// **'???'**
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
  /// **'?????摰對???銝撘萄'**
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

  /// No description provided for @removeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝘駁璅內'**
  String get removeLabel;

  /// No description provided for @labelInfoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'璅內鞈?'**
  String get labelInfoTitle;

  /// No description provided for @labelSummaryFallback.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脫?冽?蝷箄?閮?**
  String get labelSummaryFallback;

  /// No description provided for @customTabTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芾?蝢?**
  String get customTabTitle;

  /// No description provided for @customAdd.
  ///
  /// In zh_TW, this message translates to:
  /// **'??芾?蝢?**
  String get customAdd;

  /// No description provided for @customAdded.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣??亥閮儔'**
  String get customAdded;

  /// No description provided for @customEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀?瘝??芾?蝢拚???**
  String get customEmpty;

  /// No description provided for @customSelectTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?豢??芾?蝢?**
  String get customSelectTitle;

  /// No description provided for @customConfirmTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣箄?擗????**
  String get customConfirmTitle;

  /// No description provided for @customConfirmDate.
  ///
  /// In zh_TW, this message translates to:
  /// **'?交?'**
  String get customConfirmDate;

  /// No description provided for @customConfirmTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get customConfirmTime;

  /// No description provided for @customConfirmMealType.
  ///
  /// In zh_TW, this message translates to:
  /// **'擗'**
  String get customConfirmMealType;

  /// No description provided for @customUse.
  ///
  /// In zh_TW, this message translates to:
  /// **'雿輻?芾?蝢?**
  String get customUse;

  /// No description provided for @customUseSaved.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣摮閮儔擗?'**
  String get customUseSaved;

  /// No description provided for @customCountUnit.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝑?**
  String get customCountUnit;

  /// No description provided for @customEditTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝺刻摩?芾?蝢?**
  String get customEditTitle;

  /// No description provided for @customChangePhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湔??抒?'**
  String get customChangePhoto;

  /// No description provided for @customSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get customSummaryLabel;

  /// No description provided for @customSuggestionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降'**
  String get customSuggestionLabel;

  /// No description provided for @customDeleteTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芷?芾?蝢?**
  String get customDeleteTitle;

  /// No description provided for @customDeleteConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣箏??芷?閮儔嚗?**
  String get customDeleteConfirm;

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

  /// No description provided for @multiItemsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'憭???**
  String get multiItemsLabel;

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

  /// No description provided for @editCalorieTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝺刻摩?梢?'**
  String get editCalorieTitle;

  /// No description provided for @editCalorieHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘? 450-600 kcal'**
  String get editCalorieHint;

  /// No description provided for @editCalorieClear.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜'**
  String get editCalorieClear;

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
  /// **'銝遣霅唳?憭??交??皜僖?祈?撠遢'**
  String get noLateSnackSelfCook;

  /// No description provided for @noLateSnackConvenience.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅唳?憭??交???∠?鞊撚??隞賣???**
  String get noLateSnackConvenience;

  /// No description provided for @noLateSnackBento.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅唳?憭??交???遢?祈?靘輻'**
  String get noLateSnackBento;

  /// No description provided for @noLateSnackOther.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅唳?憭??交??撠?瘞湔??喳'**
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
  /// **'擗活???**
  String get mealTimeSection;

  /// No description provided for @breakfastStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拚???'**
  String get breakfastStartLabel;

  /// No description provided for @breakfastEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拚?蝯?'**
  String get breakfastEndLabel;

  /// No description provided for @brunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拙?擗?憪?**
  String get brunchStartLabel;

  /// No description provided for @brunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拙?擗???**
  String get brunchEndLabel;

  /// No description provided for @lunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????'**
  String get lunchStartLabel;

  /// No description provided for @lunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??蝯?'**
  String get lunchEndLabel;

  /// No description provided for @afternoonTeaStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??園?憪?**
  String get afternoonTeaStartLabel;

  /// No description provided for @afternoonTeaEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??嗥???**
  String get afternoonTeaEndLabel;

  /// No description provided for @dinnerStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'????'**
  String get dinnerStartLabel;

  /// No description provided for @dinnerEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??蝯?'**
  String get dinnerEndLabel;

  /// No description provided for @lateSnackStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘨???'**
  String get lateSnackStartLabel;

  /// No description provided for @lateSnackEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘨?蝯?'**
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
  /// **'隞蝮賜?'**
  String get summaryTitle;

  /// No description provided for @summaryEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予??閮?擗???**
  String get summaryEmpty;

  /// No description provided for @summaryOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?硃?４瘞港???'**
  String get summaryOilyCarb;

  /// No description provided for @summaryOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?硃'**
  String get summaryOily;

  /// No description provided for @summaryCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予蝣單偌??'**
  String get summaryCarb;

  /// No description provided for @summaryProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?鞈?OK嚗?敺?暺??**
  String get summaryProteinOk;

  /// No description provided for @summaryNeutral.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予????荔?蝜潛?靽?'**
  String get summaryNeutral;

  /// No description provided for @summaryBeverageOnly.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予?芾???憌脫?'**
  String get summaryBeverageOnly;

  /// No description provided for @includesBeverages.
  ///
  /// In zh_TW, this message translates to:
  /// **'?恍ㄡ??**
  String get includesBeverages;

  /// No description provided for @proteinIntakeTodayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?鞈?**
  String get proteinIntakeTodayLabel;

  /// No description provided for @proteinIntakeFormat.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脫???{consumed}g / ?格? {min}-{max}g'**
  String proteinIntakeFormat(int consumed, int min, int max);

  /// No description provided for @smallPortionNote.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞賡?銝?'**
  String get smallPortionNote;

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

  /// No description provided for @tabCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芾?蝢?**
  String get tabCustom;

  /// No description provided for @tabSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮剖?'**
  String get tabSettings;

  /// No description provided for @greetingTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??{name}嚗?憭拐??硃'**
  String greetingTitle(String name);

  /// No description provided for @streakLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脤??蝝??{count} 憭?**
  String streakLabel(int count);

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
  /// **'隞予??閮?擗???**
  String get latestMealEmpty;

  /// No description provided for @homeNextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'暺脣遣霅圈?嚗?銝?????獢?**
  String get homeNextMealHint;

  /// No description provided for @logTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝝??**
  String get logTitle;

  /// No description provided for @logTopMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梢??擃?擗?**
  String get logTopMealTitle;

  /// No description provided for @logTopMealEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'餈?7 憭拙??芣?摰蝝??**
  String get logTopMealEmpty;

  /// No description provided for @logRecentDaysTag.
  ///
  /// In zh_TW, this message translates to:
  /// **'餈?7 憭?{date}'**
  String logRecentDaysTag(String date);

  /// No description provided for @logAddMealPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'鋆???擗?**
  String get logAddMealPrompt;

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

  /// No description provided for @dayCardProteinLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?鞈芰???**
  String get dayCardProteinLabel;

  /// No description provided for @calorieHistoryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'熱量趨勢'**
  String get calorieHistoryTitle;

  /// No description provided for @calorieTrendTargetLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'目標 {min}-{max}'**
  String calorieTrendTargetLabel(String min, String max);

  /// No description provided for @calorieTrendSummaryWeekTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'本週總結'**
  String get calorieTrendSummaryWeekTitle;

  /// No description provided for @calorieTrendSummaryTwoWeeksTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'兩週總結'**
  String get calorieTrendSummaryTwoWeeksTitle;

  /// No description provided for @calorieTrendSummaryMonthTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月總結'**
  String get calorieTrendSummaryMonthTitle;

  /// No description provided for @calorieTrendCompareLastWeek.
  ///
  /// In zh_TW, this message translates to:
  /// **'上週'**
  String get calorieTrendCompareLastWeek;

  /// No description provided for @calorieTrendCompareLastTwoWeeks.
  ///
  /// In zh_TW, this message translates to:
  /// **'前兩週'**
  String get calorieTrendCompareLastTwoWeeks;

  /// No description provided for @calorieTrendCompareLastMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'上月'**
  String get calorieTrendCompareLastMonth;

  /// No description provided for @calorieTrendSummaryNoData.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無資料'**
  String get calorieTrendSummaryNoData;

  /// No description provided for @calorieTrendSummaryNoPrev.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} kcal，尚無前期資料。'**
  String calorieTrendSummaryNoPrev(String avg);

  /// No description provided for @calorieTrendSummaryHigher.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} kcal，高於{period} {pct}%。'**
  String calorieTrendSummaryHigher(String avg, String period, String pct);

  /// No description provided for @calorieTrendSummaryLower.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} kcal，低於{period} {pct}%。'**
  String calorieTrendSummaryLower(String avg, String period, String pct);

  /// No description provided for @calorieTrendSummarySame.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} kcal，與{period}持平。'**
  String calorieTrendSummarySame(String avg, String period);

  /// No description provided for @proteinTrendTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質趨勢'**
  String get proteinTrendTitle;

  /// No description provided for @proteinTrendTargetLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'目標 {value} g'**
  String proteinTrendTargetLabel(String value);

  /// No description provided for @proteinTrendSummaryNoData.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無資料'**
  String get proteinTrendSummaryNoData;

  /// No description provided for @proteinTrendSummaryNoPrev.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} g，尚無前期資料。'**
  String proteinTrendSummaryNoPrev(String avg);

  /// No description provided for @proteinTrendSummaryHigher.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} g，高於{period} {pct}%。'**
  String proteinTrendSummaryHigher(String avg, String period, String pct);

  /// No description provided for @proteinTrendSummaryLower.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} g，低於{period} {pct}%。'**
  String proteinTrendSummaryLower(String avg, String period, String pct);

  /// No description provided for @proteinTrendSummarySame.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均攝取 {avg} g，與{period}持平。'**
  String proteinTrendSummarySame(String avg, String period);

  /// No description provided for @dayCardMealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??擗嚗?**
  String get dayCardMealsLabel;

  /// No description provided for @dayCardSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞蝮賜?'**
  String get dayCardSummaryLabel;

  /// No description provided for @dayCardTomorrowLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?撱箄降'**
  String get dayCardTomorrowLabel;

  /// No description provided for @summaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠 {time} ?Ｙ?蝮賜?'**
  String summaryPendingAt(Object time);

  /// No description provided for @weekSummaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠 {day} {time} ?Ｙ?蝮賜?'**
  String weekSummaryPendingAt(Object day, Object time);

  /// No description provided for @finalizeDay.
  ///
  /// In zh_TW, this message translates to:
  /// **'??隞蝮賜?'**
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
  /// **'?桀????摯蝞???**
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
  /// **'??擐砌???嚗策雿???撱箄降'**
  String get suggestInstantHint;

  /// No description provided for @suggestInstantStart.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get suggestInstantStart;

  /// No description provided for @suggestInstantRetake.
  ///
  /// In zh_TW, this message translates to:
  /// **'??銝撘?**
  String get suggestInstantRetake;

  /// No description provided for @suggestInstantPickGallery.
  ///
  /// In zh_TW, this message translates to:
  /// **'敺蝪輸??**
  String get suggestInstantPickGallery;

  /// No description provided for @suggestInstantNowEat.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降??隞暻?**
  String get suggestInstantNowEat;

  /// No description provided for @suggestInstantNameHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛詨憌?迂嚗?????臭誑嚗?**
  String get suggestInstantNameHint;

  /// No description provided for @suggestInstantNameSubmit.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get suggestInstantNameSubmit;

  /// No description provided for @nameAnalyzeStart.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇???'**
  String get nameAnalyzeStart;

  /// No description provided for @nameAnalyzeEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢撓?仿??拙?蝔?**
  String get nameAnalyzeEmpty;

  /// No description provided for @suggestInstantStepDetect.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇?颲刻?擗?'**
  String get suggestInstantStepDetect;

  /// No description provided for @suggestInstantStepEstimate.
  ///
  /// In zh_TW, this message translates to:
  /// **'隡啁??梢??遢??**
  String get suggestInstantStepEstimate;

  /// No description provided for @suggestInstantStepAdvice.
  ///
  /// In zh_TW, this message translates to:
  /// **'?Ｙ???撱箄降'**
  String get suggestInstantStepAdvice;

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
  /// **'?遢憌?獐??頛末'**
  String get suggestInstantAdviceTitle;

  /// No description provided for @suggestInstantCanEat.
  ///
  /// In zh_TW, this message translates to:
  /// **'?剝?'**
  String get suggestInstantCanEat;

  /// No description provided for @suggestInstantCanDrink.
  ///
  /// In zh_TW, this message translates to:
  /// **'?臭誑??**
  String get suggestInstantCanDrink;

  /// No description provided for @suggestInstantAvoid.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅?**
  String get suggestInstantAvoid;

  /// No description provided for @suggestInstantAvoidDrink.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝遣霅啣?'**
  String get suggestInstantAvoidDrink;

  /// No description provided for @suggestInstantLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降隞賡?'**
  String get suggestInstantLimit;

  /// No description provided for @suggestInstantDrinkLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降隞賡?'**
  String get suggestInstantDrinkLimit;

  /// No description provided for @suggestInstantDrinkAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?憌脫??獐??頛末'**
  String get suggestInstantDrinkAdviceTitle;

  /// No description provided for @suggestInstantCanEatInline.
  ///
  /// In zh_TW, this message translates to:
  /// **'?臭誑?獐??**
  String get suggestInstantCanEatInline;

  /// No description provided for @suggestInstantRiskInline.
  ///
  /// In zh_TW, this message translates to:
  /// **'?航????憿?**
  String get suggestInstantRiskInline;

  /// No description provided for @suggestInstantLimitInline.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降隞賡?'**
  String get suggestInstantLimitInline;

  /// No description provided for @suggestInstantEnergyOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?舀??**
  String get suggestInstantEnergyOk;

  /// No description provided for @suggestInstantEnergyHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get suggestInstantEnergyHigh;

  /// No description provided for @suggestInstantMissing.
  ///
  /// In zh_TW, this message translates to:
  /// **'????????**
  String get suggestInstantMissing;

  /// No description provided for @suggestInstantNonFood.
  ///
  /// In zh_TW, this message translates to:
  /// **'?撐憟賢?銝憌?塚?閬?閬???甈∴?憒??曉銝?蝞?銋???嚗???擗?靘?'**
  String get suggestInstantNonFood;

  /// No description provided for @suggestInstantReestimate.
  ///
  /// In zh_TW, this message translates to:
  /// **'?隡啁?'**
  String get suggestInstantReestimate;

  /// No description provided for @suggestInstantRecentHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降撌脣???餈?7 憭抵?銝?擗?**
  String get suggestInstantRecentHint;

  /// No description provided for @suggestAutoSaved.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰?摮?**
  String get suggestAutoSaved;

  /// No description provided for @suggestTodayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?湧??斗'**
  String get suggestTodayLabel;

  /// No description provided for @suggestTodayHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予瘝寡???嚗?銝擗?瘛∩?暺?**
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
  /// **'隞予????荔?靽?撠勗末'**
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

  /// No description provided for @nicknameLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梁迂'**
  String get nicknameLabel;

  /// No description provided for @planSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮閮剖?'**
  String get planSection;

  /// No description provided for @webTestSectionTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Web 皜祈岫'**
  String get webTestSectionTitle;

  /// No description provided for @webTestSubscriptionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜祈岫閮'**
  String get webTestSubscriptionLabel;

  /// No description provided for @webTestEnabled.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣???**
  String get webTestEnabled;

  /// No description provided for @webTestDisabled.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芸???**
  String get webTestDisabled;

  /// No description provided for @webTestPlanMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'??嚗葫閰佗?'**
  String get webTestPlanMonthly;

  /// No description provided for @webTestPlanYearly.
  ///
  /// In zh_TW, this message translates to:
  /// **'撟渲?嚗葫閰佗?'**
  String get webTestPlanYearly;

  /// No description provided for @webTestPlanNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芾???**
  String get webTestPlanNone;

  /// No description provided for @webTestAccessGraceLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撽?撖祇???'**
  String get webTestAccessGraceLabel;

  /// No description provided for @webTestAccessGraceDialogTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'撽?撖祇???嚗?-168 撠?嚗?**
  String get webTestAccessGraceDialogTitle;

  /// No description provided for @webTestAccessGraceValue.
  ///
  /// In zh_TW, this message translates to:
  /// **'{hours} 撠?'**
  String webTestAccessGraceValue(int hours);

  /// No description provided for @accessStatusFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'撽?憭望?嚗?蝔??岫'**
  String get accessStatusFailed;

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

  /// No description provided for @reminderTimeNote.
  ///
  /// In zh_TW, this message translates to:
  /// **'??????擗活?????郊'**
  String get reminderTimeNote;

  /// No description provided for @reminderBreakfast.
  ///
  /// In zh_TW, this message translates to:
  /// **'?????拚?'**
  String get reminderBreakfast;

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
  /// **'?游'**
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
  /// **'瘥蝮賜?'**
  String get summaryTimeLabel;

  /// No description provided for @weeklySummaryDayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘥蝮賜?'**
  String get weeklySummaryDayLabel;

  /// No description provided for @weekTopMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?祇梁??擃?擗?**
  String get weekTopMealTitle;

  /// No description provided for @recentGuidanceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'餈??寥?嚗? 7 憭抬?'**
  String get recentGuidanceTitle;

  /// No description provided for @weekSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?祇梁蜇蝯?**
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

  /// No description provided for @activityLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘣餃???**
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

  /// No description provided for @exerciseNoExercise.
  ///
  /// In zh_TW, this message translates to:
  /// **'?⊿???**
  String get exerciseNoExercise;

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
  /// **'?⊿???**
  String get exerciseNone;

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

  /// No description provided for @commonExerciseLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撣貊??'**
  String get commonExerciseLabel;

  /// No description provided for @suggestRemainingTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞予???撠?**
  String get suggestRemainingTitle;

  /// No description provided for @suggestRemainingLeft.
  ///
  /// In zh_TW, this message translates to:
  /// **'?隞亙? {cal} kcal'**
  String suggestRemainingLeft(int cal);

  /// No description provided for @proteinRemainingLeft.
  ///
  /// In zh_TW, this message translates to:
  /// **'?隞亙? {grams} g'**
  String proteinRemainingLeft(int grams);

  /// No description provided for @suggestRemainingOver.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰???{cal} kcal'**
  String suggestRemainingOver(int cal);

  /// No description provided for @proteinRemainingOver.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰???{grams} g'**
  String proteinRemainingOver(int grams);

  /// No description provided for @suggestExerciseHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'撱箄降??{exercise} 蝝?{minutes} ??'**
  String suggestExerciseHint(String exercise, int minutes);

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

  /// No description provided for @reminderBreakfastTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拚?????'**
  String get reminderBreakfastTime;

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

  /// No description provided for @glowToggleLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???'**
  String get glowToggleLabel;

  /// No description provided for @themeGreen.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜蝬?**
  String get themeGreen;

  /// No description provided for @themeWarm.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get themeWarm;

  /// No description provided for @themePink.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get themePink;

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

  /// No description provided for @apiBaseUrlReset.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜??API 銝阡?閮?**
  String get apiBaseUrlReset;

  /// No description provided for @apiBaseUrlResetDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脤?閮?API 雿?'**
  String get apiBaseUrlResetDone;

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
  /// **'AI 隡啁?'**
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
  /// **'?桀??⊥???'**
  String get analyzeFailed;

  /// No description provided for @reestimateFailedKeepLast.
  ///
  /// In zh_TW, this message translates to:
  /// **'?隡啁?憭望?嚗歇靽?銝?????**
  String get reestimateFailedKeepLast;

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
  /// **'?汗'**
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

  /// No description provided for @nutritionValueLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'??憿舐內'**
  String get nutritionValueLabel;

  /// No description provided for @nutritionValuePercent.
  ///
  /// In zh_TW, this message translates to:
  /// **'?曉?瘥?**
  String get nutritionValuePercent;

  /// No description provided for @nutritionValueAmount.
  ///
  /// In zh_TW, this message translates to:
  /// **'?詨?**
  String get nutritionValueAmount;

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

  /// No description provided for @syncSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'撣唾???甇?**
  String get syncSection;

  /// No description provided for @syncSignedInAs.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脩?伐?'**
  String get syncSignedInAs;

  /// No description provided for @syncNotSignedIn.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠?餃'**
  String get syncNotSignedIn;

  /// No description provided for @syncEmailLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email'**
  String get syncEmailLabel;

  /// No description provided for @syncPasswordLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撖Ⅳ'**
  String get syncPasswordLabel;

  /// No description provided for @syncSignIn.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃'**
  String get syncSignIn;

  /// No description provided for @syncSignUp.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?'**
  String get syncSignUp;

  /// No description provided for @syncSignUpSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣???霅縑嚗????縑蝞梢?霅?**
  String get syncSignUpSuccess;

  /// No description provided for @syncSignInSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃??'**
  String get syncSignInSuccess;

  /// No description provided for @syncForgotPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'敹?撖Ⅳ'**
  String get syncForgotPassword;

  /// No description provided for @syncResetPasswordTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?身撖Ⅳ'**
  String get syncResetPasswordTitle;

  /// No description provided for @syncResetPasswordHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛詨閮餃?靽∠拳'**
  String get syncResetPasswordHint;

  /// No description provided for @syncResetPasswordSent.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣???閮剖?蝣潮隞?**
  String get syncResetPasswordSent;

  /// No description provided for @syncSignOut.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃'**
  String get syncSignOut;

  /// No description provided for @syncSwitchAccount.
  ///
  /// In zh_TW, this message translates to:
  /// **'??撣唾?'**
  String get syncSwitchAccount;

  /// No description provided for @syncSwitchAccountConfirmTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'??撣唾?'**
  String get syncSwitchAccountConfirmTitle;

  /// No description provided for @syncSwitchAccountConfirmMessage.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠??斗璈??蒂?餃嚗Ⅱ摰???撣唾???'**
  String get syncSwitchAccountConfirmMessage;

  /// No description provided for @syncSwitchAccountConfirmAction.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get syncSwitchAccountConfirmAction;

  /// No description provided for @syncSwitchAccountDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣??董??鞈?撌脫?蝛箝?**
  String get syncSwitchAccountDone;

  /// No description provided for @syncUpload.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?郊'**
  String get syncUpload;

  /// No description provided for @syncDownload.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??郊'**
  String get syncDownload;

  /// No description provided for @syncNow.
  ///
  /// In zh_TW, this message translates to:
  /// **'?郊'**
  String get syncNow;

  /// No description provided for @syncInProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇??芸??郊銝凌?**
  String get syncInProgress;

  /// No description provided for @syncLastSyncLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝活?郊嚗?**
  String get syncLastSyncLabel;

  /// No description provided for @syncLastResultLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝活蝯?嚗?**
  String get syncLastResultLabel;

  /// No description provided for @syncLastResultNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠蝝??**
  String get syncLastResultNone;

  /// No description provided for @syncLastResultNoChanges.
  ///
  /// In zh_TW, this message translates to:
  /// **'?∟???**
  String get syncLastResultNoChanges;

  /// No description provided for @syncFailedItemsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'憭望??嚗?**
  String get syncFailedItemsLabel;

  /// Failed sync item count
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} ??**
  String syncFailedItemsCount(int count);

  /// No description provided for @syncRetryFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'?岫憭望???**
  String get syncRetryFailed;

  /// No description provided for @syncSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'?郊摰???**
  String get syncSuccess;

  /// No description provided for @syncUpdated.
  ///
  /// In zh_TW, this message translates to:
  /// **'?湔摰?'**
  String get syncUpdated;

  /// No description provided for @syncNoChanges.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀?瘝?閬?甇亦?鞈?'**
  String get syncNoChanges;

  /// No description provided for @syncError.
  ///
  /// In zh_TW, this message translates to:
  /// **'?郊憭望?嚗?蝔??岫'**
  String get syncError;

  /// No description provided for @syncRequireLogin.
  ///
  /// In zh_TW, this message translates to:
  /// **'??交??賢?甇亙?'**
  String get syncRequireLogin;

  /// No description provided for @syncAuthTitleSignIn.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃撣唾?'**
  String get syncAuthTitleSignIn;

  /// No description provided for @syncAuthTitleSignUp.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?撣唾?'**
  String get syncAuthTitleSignUp;

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

  /// No description provided for @close.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get close;

  /// No description provided for @authTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇∟?雿輻 Food AI'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃敺?臭蝙?典??游???**
  String get authSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢撓??Email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email ?澆?銝迤蝣?**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'撖Ⅳ'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣箄?撖Ⅳ'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authSignIn.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?'**
  String get authSignUp;

  /// No description provided for @authToggleToSignUp.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘝?撣唾?嚗??唾酉??**
  String get authToggleToSignUp;

  /// No description provided for @authToggleToSignIn.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脫?撣唾?嚗????**
  String get authToggleToSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'敹?撖Ⅳ'**
  String get authForgotPassword;

  /// No description provided for @authSignInSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃??'**
  String get authSignInSuccess;

  /// No description provided for @authSignUpSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?摰?'**
  String get authSignUpSuccess;

  /// No description provided for @authSignUpVerify.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?摰?嚗???靽∠拳摰?撽?'**
  String get authSignUpVerify;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇?Email 撠撽?嚗????縑蝞梢?霅?**
  String get authEmailNotVerified;

  /// No description provided for @authVerifyTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢?霅縑蝞?**
  String get authVerifyTitle;

  /// No description provided for @authVerifyBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'?歇撖?霅縑??{email}嚗???1-3 ???扳??銋?瑼Ｘ??萎辣/靽???**
  String authVerifyBody(String email);

  /// No description provided for @authResend.
  ///
  /// In zh_TW, this message translates to:
  /// **'?撖?霅縑'**
  String get authResend;

  /// No description provided for @authResendCooldown.
  ///
  /// In zh_TW, this message translates to:
  /// **'?撖?{seconds}s嚗?**
  String authResendCooldown(int seconds);

  /// No description provided for @authResendSent.
  ///
  /// In zh_TW, this message translates to:
  /// **'撽?靽∪歇?撖'**
  String get authResendSent;

  /// No description provided for @authResendFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'?撖仃??隢?敺?閰?**
  String get authResendFailed;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢?敺?閰?**
  String get authTooManyAttempts;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In zh_TW, this message translates to:
  /// **'?拇活撖Ⅳ銝???**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordRule.
  ///
  /// In zh_TW, this message translates to:
  /// **'撖Ⅳ?喳? 8 蝣潘?銝??臬蝛箇?葉??**
  String get authPasswordRule;

  /// No description provided for @authPasswordInvalid.
  ///
  /// In zh_TW, this message translates to:
  /// **'撖Ⅳ??喳? 8 蝣潘?銝??臬蝛箇?葉??**
  String get authPasswordInvalid;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'重設密碼'**
  String get authResetPasswordTitle;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'新密碼'**
  String get authNewPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入密碼'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼已更新'**
  String get authPasswordUpdated;

  /// No description provided for @authResetPasswordAction.
  ///
  /// In zh_TW, this message translates to:
  /// **'更新密碼'**
  String get authResetPasswordAction;

  /// No description provided for @authResetLinkInvalid.
  ///
  /// In zh_TW, this message translates to:
  /// **'連結已失效，請重新寄送重設密碼信'**
  String get authResetLinkInvalid;

  /// No description provided for @authResetSent.
  ///
  /// In zh_TW, this message translates to:
  /// **'?身撖Ⅳ靽∪歇撖嚗??亦?靽∠拳'**
  String get authResetSent;

  /// No description provided for @authResetFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'?身憭望?嚗?蝣箄? Email ?臬甇?Ⅱ'**
  String get authResetFailed;

  /// No description provided for @authLoginInvalid.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email ??蝣潮隤?**
  String get authLoginInvalid;

  /// No description provided for @authEmailExists.
  ///
  /// In zh_TW, this message translates to:
  /// **'甇?Email 撌脰酉??**
  String get authEmailExists;

  /// No description provided for @authNetworkError.
  ///
  /// In zh_TW, this message translates to:
  /// **'????啣虜嚗?蝔??岫'**
  String get authNetworkError;

  /// No description provided for @authSignUpFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮餃?憭望?'**
  String get authSignUpFailed;

  /// No description provided for @authError.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃憭望?嚗?蝔??岫'**
  String get authError;

  /// No description provided for @trialExpiredTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閰衣?歇蝯?'**
  String get trialExpiredTitle;

  /// No description provided for @trialExpiredBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'雿歇摰? 2 憭拙?鞎餉岫?剁?隢??勗?蝜潛?雿輻 AI ?????**
  String get trialExpiredBody;

  /// No description provided for @trialExpiredAction.
  ///
  /// In zh_TW, this message translates to:
  /// **'鈭圾?寞?'**
  String get trialExpiredAction;

  /// No description provided for @signOut.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃'**
  String get signOut;

  /// No description provided for @dietPreferenceSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'憌脤??末'**
  String get dietPreferenceSection;

  /// No description provided for @dietTypeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'憌脤?憿?'**
  String get dietTypeLabel;

  /// No description provided for @dietNoteLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?末鋆?'**
  String get dietNoteLabel;

  /// No description provided for @dietTypeNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝???**
  String get dietTypeNone;

  /// No description provided for @dietTypeVegetarian.
  ///
  /// In zh_TW, this message translates to:
  /// **'憟嗉?蝝?**
  String get dietTypeVegetarian;

  /// No description provided for @dietTypeVegan.
  ///
  /// In zh_TW, this message translates to:
  /// **'?函?'**
  String get dietTypeVegan;

  /// No description provided for @dietTypePescatarian.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘚琿悅蝝?**
  String get dietTypePescatarian;

  /// No description provided for @dietTypeLowCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'雿４'**
  String get dietTypeLowCarb;

  /// No description provided for @dietTypeKeto.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get dietTypeKeto;

  /// No description provided for @dietTypeLowFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'雿?'**
  String get dietTypeLowFat;

  /// No description provided for @dietTypeHighProtein.
  ///
  /// In zh_TW, this message translates to:
  /// **'擃???**
  String get dietTypeHighProtein;

  /// No description provided for @authNicknameRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢撓?交蝔?**
  String get authNicknameRequired;

  /// No description provided for @containerSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'撣貊摰孵'**
  String get containerSection;

  /// No description provided for @containerTypeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'摰孵憿?'**
  String get containerTypeLabel;

  /// No description provided for @containerSizeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'摰孵撠箏站'**
  String get containerSizeLabel;

  /// No description provided for @containerDepthLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣楛摨?**
  String get containerDepthLabel;

  /// No description provided for @containerDiameterLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?游? (cm)'**
  String get containerDiameterLabel;

  /// No description provided for @containerCapacityLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'摰寥? (ml)'**
  String get containerCapacityLabel;

  /// No description provided for @containerTypeBowl.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝣?**
  String get containerTypeBowl;

  /// No description provided for @containerTypePlate.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get containerTypePlate;

  /// No description provided for @containerTypeBox.
  ///
  /// In zh_TW, this message translates to:
  /// **'靘輻??**
  String get containerTypeBox;

  /// No description provided for @containerTypeCup.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get containerTypeCup;

  /// No description provided for @containerTypeUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?摰?**
  String get containerTypeUnknown;

  /// No description provided for @containerSizeSmall.
  ///
  /// In zh_TW, this message translates to:
  /// **'撠?**
  String get containerSizeSmall;

  /// No description provided for @containerSizeMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?**
  String get containerSizeMedium;

  /// No description provided for @containerSizeLarge.
  ///
  /// In zh_TW, this message translates to:
  /// **'憭?**
  String get containerSizeLarge;

  /// No description provided for @containerSizeStandard.
  ///
  /// In zh_TW, this message translates to:
  /// **'璅?'**
  String get containerSizeStandard;

  /// No description provided for @containerSizeCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芾?'**
  String get containerSizeCustom;

  /// No description provided for @containerDepthShallow.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘛?**
  String get containerDepthShallow;

  /// No description provided for @containerDepthMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?**
  String get containerDepthMedium;

  /// No description provided for @containerDepthDeep.
  ///
  /// In zh_TW, this message translates to:
  /// **'瘛?**
  String get containerDepthDeep;

  /// No description provided for @paywallTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閫??摰?'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI ????擗??梧??蜇蝯?**
  String get paywallSubtitle;

  /// No description provided for @planMonthlyWithPrice.
  ///
  /// In zh_TW, this message translates to:
  /// **'?? {price}'**
  String planMonthlyWithPrice(String price);

  /// No description provided for @planYearlyWithPrice.
  ///
  /// In zh_TW, this message translates to:
  /// **'撟渲? {price}'**
  String planYearlyWithPrice(String price);

  /// No description provided for @paywallYearlyBadge.
  ///
  /// In zh_TW, this message translates to:
  /// **'撟渲???蝝?30%'**
  String get paywallYearlyBadge;

  /// No description provided for @paywallRestore.
  ///
  /// In zh_TW, this message translates to:
  /// **'?Ｗ儔鞈潸眺'**
  String get paywallRestore;

  /// No description provided for @paywallDisclaimer.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮撠??閮??舫? Apple ID 閮蝞∠?銝剖?瘨?甈曄 Apple ????**
  String get paywallDisclaimer;

  /// No description provided for @paywallStartMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'????'**
  String get paywallStartMonthly;

  /// No description provided for @paywallStartYearly.
  ///
  /// In zh_TW, this message translates to:
  /// **'??撟渲?'**
  String get paywallStartYearly;

  /// No description provided for @paywallFeatureAiAnalysis.
  ///
  /// In zh_TW, this message translates to:
  /// **'摰 AI ??'**
  String get paywallFeatureAiAnalysis;

  /// No description provided for @paywallFeatureNutritionAdvice.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梢???擗遣霅?**
  String get paywallFeatureNutritionAdvice;

  /// No description provided for @paywallFeatureSummaries.
  ///
  /// In zh_TW, this message translates to:
  /// **'?梧??蜇蝯?**
  String get paywallFeatureSummaries;

  /// No description provided for @paywallFeatureBestValue.
  ///
  /// In zh_TW, this message translates to:
  /// **'?游?蝞??瑟??寞?'**
  String get paywallFeatureBestValue;

  /// No description provided for @paywallUnavailableTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'?⊥?頛閮'**
  String get paywallUnavailableTitle;

  /// No description provided for @paywallUnavailableBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀??⊥??? App Store 閮鞈?嚗?蝔??岫??**
  String get paywallUnavailableBody;

  /// No description provided for @webPaywallTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閫??摰?嚗eb 皜祈岫嚗?**
  String get webPaywallTitle;

  /// No description provided for @webPaywallTestBadge.
  ///
  /// In zh_TW, this message translates to:
  /// **'??皜祈岫嚗??甈?**
  String get webPaywallTestBadge;

  /// No description provided for @webPaywallCurrentPlanMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀??寞?嚗?閮?皜祈岫嚗?**
  String get webPaywallCurrentPlanMonthly;

  /// No description provided for @webPaywallCurrentPlanYearly.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀??寞?嚗僑閮?皜祈岫嚗?**
  String get webPaywallCurrentPlanYearly;

  /// No description provided for @webPaywallCurrentPlanNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'?桀??寞?嚗閮'**
  String get webPaywallCurrentPlanNone;

  /// No description provided for @webPaywallTestNote.
  ///
  /// In zh_TW, this message translates to:
  /// **'Web 皜祈岫??甇斗?蝔??祕?甈整?**
  String get webPaywallTestNote;

  /// No description provided for @webPaywallActivated.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脣??冽葫閰西???**
  String get webPaywallActivated;

  /// No description provided for @webPaywallSuccessTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜祈岫閮??'**
  String get webPaywallSuccessTitle;

  /// No description provided for @webPaywallSuccessBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰圾???游??踝?皜祈岫璅∪?嚗?**
  String get webPaywallSuccessBody;

  /// No description provided for @webPaywallSuccessCta.
  ///
  /// In zh_TW, this message translates to:
  /// **'??雿輻'**
  String get webPaywallSuccessCta;

  /// No description provided for @dialogOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'?仿?鈭?**
  String get dialogOk;

  /// No description provided for @syncErrorUploadFailedDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'??銝憭望?'**
  String get syncErrorUploadFailedDetail;

  /// No description provided for @syncErrorSyncMetaFailedDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'?郊??神?亙仃??**
  String get syncErrorSyncMetaFailedDetail;

  /// No description provided for @syncErrorPostgrestDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'鞈?摨怠??仃??**
  String get syncErrorPostgrestDetail;

  /// No description provided for @syncErrorNetworkDetail.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝬脰楝???憭望?'**
  String get syncErrorNetworkDetail;

  /// No description provided for @syncSummaryUploadMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝擗? {count}'**
  String syncSummaryUploadMeals(int count);

  /// No description provided for @syncSummaryDeleteMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芷擗? {count}'**
  String syncSummaryDeleteMeals(int count);

  /// No description provided for @syncSummaryUploadCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?芾?憌 {count}'**
  String syncSummaryUploadCustom(int count);

  /// No description provided for @syncSummaryDeleteCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芷?芾?憌 {count}'**
  String syncSummaryDeleteCustom(int count);

  /// No description provided for @syncSummaryUploadSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝閮剖? {count}'**
  String syncSummaryUploadSettings(int count);

  /// No description provided for @syncSummaryDownloadMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?擗? {count}'**
  String syncSummaryDownloadMeals(int count);

  /// No description provided for @syncSummaryDownloadDeletedMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??芷擗? {count}'**
  String syncSummaryDownloadDeletedMeals(int count);

  /// No description provided for @syncSummaryDownloadCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??芾?憌 {count}'**
  String syncSummaryDownloadCustom(int count);

  /// No description provided for @syncSummaryDownloadDeletedCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝??芷?芾?憌 {count}'**
  String syncSummaryDownloadDeletedCustom(int count);

  /// No description provided for @syncSummaryDownloadSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝?閮剖? {count}'**
  String syncSummaryDownloadSettings(int count);

  /// No description provided for @syncSummarySeparator.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get syncSummarySeparator;

  /// No description provided for @plateJapanese02.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亙???02'**
  String get plateJapanese02;

  /// No description provided for @plateJapanese04.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亙???04'**
  String get plateJapanese04;

  /// No description provided for @plateChina01.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剖???01'**
  String get plateChina01;

  /// No description provided for @plateChina02.
  ///
  /// In zh_TW, this message translates to:
  /// **'銝剖???02'**
  String get plateChina02;

  /// No description provided for @placeholderDash.
  ///
  /// In zh_TW, this message translates to:
  /// **'--'**
  String get placeholderDash;

  /// No description provided for @valueWithCm.
  ///
  /// In zh_TW, this message translates to:
  /// **'{value} ?砍?'**
  String valueWithCm(int value);

  /// No description provided for @valueWithKg.
  ///
  /// In zh_TW, this message translates to:
  /// **'{value} ?祆'**
  String valueWithKg(int value);

  /// No description provided for @valueWithMl.
  ///
  /// In zh_TW, this message translates to:
  /// **'{value} 瘥怠?'**
  String valueWithMl(int value);

  /// No description provided for @referenceObjectLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?'**
  String get referenceObjectLabel;

  /// No description provided for @referenceObjectNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'??**
  String get referenceObjectNone;

  /// No description provided for @referenceObjectCard.
  ///
  /// In zh_TW, this message translates to:
  /// **'靽∠??**
  String get referenceObjectCard;

  /// No description provided for @referenceObjectCoin10.
  ///
  /// In zh_TW, this message translates to:
  /// **'10 ?′撟?**
  String get referenceObjectCoin10;

  /// No description provided for @referenceObjectCoin5.
  ///
  /// In zh_TW, this message translates to:
  /// **'5 ?′撟?**
  String get referenceObjectCoin5;

  /// No description provided for @referenceObjectManual.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜祈?嚗??'**
  String get referenceObjectManual;

  /// No description provided for @referenceLengthLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜祈??瑕漲嚗??'**
  String get referenceLengthLabel;

  /// No description provided for @referenceLengthHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'頛詨 iOS 皜祈?????**
  String get referenceLengthHint;

  /// No description provided for @referenceLengthApply.
  ///
  /// In zh_TW, this message translates to:
  /// **'憟'**
  String get referenceLengthApply;

  /// No description provided for @tabChatAssistant.
  ///
  /// In zh_TW, this message translates to:
  /// **'??'**
  String get tabChatAssistant;

  /// No description provided for @chatEmptyHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'?剁????嚗??ㄡ憌??格??改?'**
  String get chatEmptyHint;

  /// No description provided for @chatEmptyHintWithName.
  ///
  /// In zh_TW, this message translates to:
  /// **'?剁??{name}嚗??ㄡ憌??格??改?'**
  String chatEmptyHintWithName(Object name);

  /// No description provided for @chatInputHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'????...'**
  String get chatInputHint;

  /// No description provided for @chatLockedTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮?喳???予'**
  String get chatLockedTitle;

  /// No description provided for @chatLockedBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮敺?脣??犖?ㄡ憌遣霅啗?閫????**
  String get chatLockedBody;

  /// No description provided for @chatLockedAction.
  ///
  /// In zh_TW, this message translates to:
  /// **'?亦?閮'**
  String get chatLockedAction;

  /// No description provided for @chatClearTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜?予蝝??'**
  String get chatClearTitle;

  /// No description provided for @chatClearBody.
  ///
  /// In zh_TW, this message translates to:
  /// **'??蝘駁?祆?銝?撠店?批捆??**
  String get chatClearBody;

  /// No description provided for @chatClearConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'皜'**
  String get chatClearConfirm;

  /// No description provided for @chatError.
  ///
  /// In zh_TW, this message translates to:
  /// **'?予憭望?嚗?蝔??岫'**
  String get chatError;

  /// No description provided for @chatErrorAuth.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃撌脤???隢??啁??**
  String get chatErrorAuth;

  /// No description provided for @chatErrorQuota.
  ///
  /// In zh_TW, this message translates to:
  /// **'隞?予憿漲撌脩摰?隢?敺?閰?**
  String get chatErrorQuota;

  /// No description provided for @chatErrorServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'?萄?嚚???敹?蝔??岫'**
  String get chatErrorServer;

  /// No description provided for @chatErrorNetwork.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝬脰楝銝帘摰?隢?敺?閰?**
  String get chatErrorNetwork;

  /// No description provided for @chatErrorReplyBase.
  ///
  /// In zh_TW, this message translates to:
  /// **'?萄?嚚?????蝝荔?蝔?????甈∪末??'**
  String get chatErrorReplyBase;

  /// No description provided for @chatErrorReasonPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'??嚗?**
  String get chatErrorReasonPrefix;

  /// No description provided for @chatErrorReasonAuth.
  ///
  /// In zh_TW, this message translates to:
  /// **'?餃撌脤???甈?銝雲'**
  String get chatErrorReasonAuth;

  /// No description provided for @chatErrorReasonQuota.
  ///
  /// In zh_TW, this message translates to:
  /// **'隢?憭芷蝜?憿漲撌脩摰?**
  String get chatErrorReasonQuota;

  /// No description provided for @chatErrorReasonServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'隡箸??典?蝣??急??粹'**
  String get chatErrorReasonServer;

  /// No description provided for @chatErrorReasonNetwork.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝬脰楝銝帘摰????銝剜'**
  String get chatErrorReasonNetwork;

  /// No description provided for @chatErrorReasonUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'?急??⊥??斗'**
  String get chatErrorReasonUnknown;

  /// No description provided for @chatAvatarLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'?予?剖?'**
  String get chatAvatarLabel;

  /// No description provided for @chatAssistantNameLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'???迂'**
  String get chatAssistantNameLabel;

  /// No description provided for @chatAvatarSet.
  ///
  /// In zh_TW, this message translates to:
  /// **'撌脰身摰?**
  String get chatAvatarSet;

  /// No description provided for @chatAvatarUnset.
  ///
  /// In zh_TW, this message translates to:
  /// **'?芾身摰?**
  String get chatAvatarUnset;

  /// No description provided for @chatAvatarSheetTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閮剖??予?剖?'**
  String get chatAvatarSheetTitle;

  /// No description provided for @chatAvatarPick.
  ///
  /// In zh_TW, this message translates to:
  /// **'?豢??抒?'**
  String get chatAvatarPick;

  /// No description provided for @chatAvatarRemove.
  ///
  /// In zh_TW, this message translates to:
  /// **'蝘駁?抒?'**
  String get chatAvatarRemove;
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
