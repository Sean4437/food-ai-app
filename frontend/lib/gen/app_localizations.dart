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
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
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
  /// **'飲食 AI MVP'**
  String get appTitle;

  /// No description provided for @takePhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍照紀錄'**
  String get takePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'上傳照片'**
  String get uploadPhoto;

  /// No description provided for @quickAdd.
  ///
  /// In zh_TW, this message translates to:
  /// **'快速新增（自動分餐）'**
  String get quickAdd;

  /// No description provided for @breakfast.
  ///
  /// In zh_TW, this message translates to:
  /// **'早餐'**
  String get breakfast;

  /// No description provided for @brunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'早午餐'**
  String get brunch;

  /// No description provided for @lunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'中餐'**
  String get lunch;

  /// No description provided for @afternoonTea.
  ///
  /// In zh_TW, this message translates to:
  /// **'下午茶'**
  String get afternoonTea;

  /// No description provided for @dinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'晚餐'**
  String get dinner;

  /// No description provided for @lateSnack.
  ///
  /// In zh_TW, this message translates to:
  /// **'消夜'**
  String get lateSnack;

  /// No description provided for @other.
  ///
  /// In zh_TW, this message translates to:
  /// **'其他'**
  String get other;

  /// No description provided for @timeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'時間'**
  String get timeLabel;

  /// No description provided for @editTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'修改時間'**
  String get editTime;

  /// No description provided for @noEntries.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無紀錄'**
  String get noEntries;

  /// No description provided for @mealTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'本餐估計熱量'**
  String get mealTotal;

  /// No description provided for @mealSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'本菜摘要'**
  String get mealSummaryTitle;

  /// No description provided for @todayMeals.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日餐點'**
  String get todayMeals;

  /// No description provided for @itemsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 筆'**
  String itemsCount(int count);

  /// No description provided for @captureTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍照紀錄'**
  String get captureTitle;

  /// No description provided for @captureHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍下你正在吃的餐點即可'**
  String get captureHint;

  /// No description provided for @optionalNoteLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'補充說明（可選）'**
  String get optionalNoteLabel;

  /// No description provided for @notePlaceholder.
  ///
  /// In zh_TW, this message translates to:
  /// **'例如：只吃一半、打包帶走'**
  String get notePlaceholder;

  /// No description provided for @recentPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'最近照片'**
  String get recentPhotos;

  /// No description provided for @noPhotos.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未新增照片'**
  String get noPhotos;

  /// No description provided for @analysisTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'餐點分析'**
  String get analysisTitle;

  /// No description provided for @analysisEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'還沒有餐點分析，先拍一張吧'**
  String get analysisEmpty;

  /// No description provided for @foodNameLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'食物名稱'**
  String get foodNameLabel;

  /// No description provided for @editFoodName.
  ///
  /// In zh_TW, this message translates to:
  /// **'修改食物名稱'**
  String get editFoodName;

  /// No description provided for @reanalyzeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'重新分析'**
  String get reanalyzeLabel;

  /// No description provided for @addLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'補充標示'**
  String get addLabel;

  /// No description provided for @removeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'移除標示'**
  String get removeLabel;

  /// No description provided for @labelInfoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'標示資訊'**
  String get labelInfoTitle;

  /// No description provided for @labelSummaryFallback.
  ///
  /// In zh_TW, this message translates to:
  /// **'已採用標示資訊'**
  String get labelSummaryFallback;

  /// No description provided for @customTabTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'自訂義'**
  String get customTabTitle;

  /// No description provided for @customAdd.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入自訂義'**
  String get customAdd;

  /// No description provided for @customAdded.
  ///
  /// In zh_TW, this message translates to:
  /// **'已加入自訂義'**
  String get customAdded;

  /// No description provided for @customEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前沒有自訂義項目'**
  String get customEmpty;

  /// No description provided for @customSelectTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇自訂義'**
  String get customSelectTitle;

  /// No description provided for @customConfirmTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'確認餐別與時間'**
  String get customConfirmTitle;

  /// No description provided for @customConfirmDate.
  ///
  /// In zh_TW, this message translates to:
  /// **'日期'**
  String get customConfirmDate;

  /// No description provided for @customConfirmTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'時間'**
  String get customConfirmTime;

  /// No description provided for @customConfirmMealType.
  ///
  /// In zh_TW, this message translates to:
  /// **'餐別'**
  String get customConfirmMealType;

  /// No description provided for @customUse.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用自訂義'**
  String get customUse;

  /// No description provided for @customUseSaved.
  ///
  /// In zh_TW, this message translates to:
  /// **'已儲存自訂義餐點'**
  String get customUseSaved;

  /// No description provided for @customCountUnit.
  ///
  /// In zh_TW, this message translates to:
  /// **'筆'**
  String get customCountUnit;

  /// No description provided for @customEditTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯自訂義'**
  String get customEditTitle;

  /// No description provided for @customChangePhoto.
  ///
  /// In zh_TW, this message translates to:
  /// **'更換照片'**
  String get customChangePhoto;

  /// No description provided for @customSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'本菜摘要'**
  String get customSummaryLabel;

  /// No description provided for @customSuggestionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議'**
  String get customSuggestionLabel;

  /// No description provided for @customDeleteTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除自訂義'**
  String get customDeleteTitle;

  /// No description provided for @customDeleteConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定刪除這個自訂義？'**
  String get customDeleteConfirm;

  /// No description provided for @unknownFood.
  ///
  /// In zh_TW, this message translates to:
  /// **'未命名餐點'**
  String get unknownFood;

  /// No description provided for @dietitianPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議：'**
  String get dietitianPrefix;

  /// No description provided for @dietitianBalanced.
  ///
  /// In zh_TW, this message translates to:
  /// **'整體均衡，維持即可。'**
  String get dietitianBalanced;

  /// No description provided for @dietitianProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質偏低，建議補豆魚蛋肉。'**
  String get dietitianProteinLow;

  /// No description provided for @dietitianFatHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'油脂偏高，下一餐清淡少油。'**
  String get dietitianFatHigh;

  /// No description provided for @dietitianCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'碳水偏多，主食減量。'**
  String get dietitianCarbHigh;

  /// No description provided for @dietitianSodiumHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'鈉含量偏高，減少湯底與加工品。'**
  String get dietitianSodiumHigh;

  /// No description provided for @goalAdviceLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'以減脂為目標，下一餐以蛋白質與蔬菜為主。'**
  String get goalAdviceLoseFat;

  /// No description provided for @goalAdviceMaintain.
  ///
  /// In zh_TW, this message translates to:
  /// **'以維持為主，注意份量與均衡。'**
  String get goalAdviceMaintain;

  /// No description provided for @overallLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'整體判斷'**
  String get overallLabel;

  /// No description provided for @calorieLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'熱量區間'**
  String get calorieLabel;

  /// No description provided for @macroLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'三大營養'**
  String get macroLabel;

  /// No description provided for @levelLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'低'**
  String get levelLow;

  /// No description provided for @levelMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'中'**
  String get levelMedium;

  /// No description provided for @levelHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'高'**
  String get levelHigh;

  /// No description provided for @statusOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @statusWarn.
  ///
  /// In zh_TW, this message translates to:
  /// **'偏多'**
  String get statusWarn;

  /// No description provided for @statusOver.
  ///
  /// In zh_TW, this message translates to:
  /// **'爆'**
  String get statusOver;

  /// No description provided for @tagOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'偏油'**
  String get tagOily;

  /// No description provided for @tagProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質足'**
  String get tagProteinOk;

  /// No description provided for @tagProteinLow.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質不足'**
  String get tagProteinLow;

  /// No description provided for @tagCarbHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'碳水偏多'**
  String get tagCarbHigh;

  /// No description provided for @tagOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'OK'**
  String get tagOk;

  /// No description provided for @nextMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'下一餐建議怎麼吃'**
  String get nextMealTitle;

  /// No description provided for @nextMealSectionTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'下一餐建議怎麼吃'**
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
  /// **'選一個最方便的方式就好'**
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

  /// No description provided for @mealItemsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'返回本餐'**
  String get mealItemsTitle;

  /// No description provided for @mealTimeSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'餐次區間'**
  String get mealTimeSection;

  /// No description provided for @breakfastStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'早餐開始'**
  String get breakfastStartLabel;

  /// No description provided for @breakfastEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'早餐結束'**
  String get breakfastEndLabel;

  /// No description provided for @brunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'早午餐開始'**
  String get brunchStartLabel;

  /// No description provided for @brunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'早午餐結束'**
  String get brunchEndLabel;

  /// No description provided for @lunchStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'午餐開始'**
  String get lunchStartLabel;

  /// No description provided for @lunchEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'午餐結束'**
  String get lunchEndLabel;

  /// No description provided for @afternoonTeaStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'下午茶開始'**
  String get afternoonTeaStartLabel;

  /// No description provided for @afternoonTeaEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'下午茶結束'**
  String get afternoonTeaEndLabel;

  /// No description provided for @dinnerStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'晚餐開始'**
  String get dinnerStartLabel;

  /// No description provided for @dinnerEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'晚餐結束'**
  String get dinnerEndLabel;

  /// No description provided for @lateSnackStartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'消夜開始'**
  String get lateSnackStartLabel;

  /// No description provided for @lateSnackEndLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'消夜結束'**
  String get lateSnackEndLabel;

  /// No description provided for @optionConvenienceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'便利商店'**
  String get optionConvenienceTitle;

  /// No description provided for @optionConvenienceDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'選茶葉蛋/無糖豆漿/沙拉，少炸物'**
  String get optionConvenienceDesc;

  /// No description provided for @optionBentoTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'便當店'**
  String get optionBentoTitle;

  /// No description provided for @optionBentoDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'半飯、多蔬菜、優先選烤或滷'**
  String get optionBentoDesc;

  /// No description provided for @optionLightTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'清淡選擇'**
  String get optionLightTitle;

  /// No description provided for @optionLightDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'清湯、蒸煮、少醬料'**
  String get optionLightDesc;

  /// No description provided for @summaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日摘要'**
  String get summaryTitle;

  /// No description provided for @summaryEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天尚未記錄餐點'**
  String get summaryEmpty;

  /// No description provided for @summaryOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天外食偏油、碳水偏多'**
  String get summaryOilyCarb;

  /// No description provided for @summaryOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天外食偏油'**
  String get summaryOily;

  /// No description provided for @summaryCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天碳水偏多'**
  String get summaryCarb;

  /// No description provided for @summaryProteinOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質尚可，記得補蔬菜'**
  String get summaryProteinOk;

  /// No description provided for @summaryNeutral.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天整體還不錯，維持即可'**
  String get summaryNeutral;

  /// No description provided for @mealsCountLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'已記錄'**
  String get mealsCountLabel;

  /// No description provided for @mealsLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'餐'**
  String get mealsLabel;

  /// No description provided for @tabCapture.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍照'**
  String get tabCapture;

  /// No description provided for @tabAnalysis.
  ///
  /// In zh_TW, this message translates to:
  /// **'分析'**
  String get tabAnalysis;

  /// No description provided for @tabNext.
  ///
  /// In zh_TW, this message translates to:
  /// **'下一餐'**
  String get tabNext;

  /// No description provided for @tabSummary.
  ///
  /// In zh_TW, this message translates to:
  /// **'摘要'**
  String get tabSummary;

  /// No description provided for @tabHome.
  ///
  /// In zh_TW, this message translates to:
  /// **'首頁'**
  String get tabHome;

  /// No description provided for @tabLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'紀錄'**
  String get tabLog;

  /// No description provided for @tabSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'即拍建議'**
  String get tabSuggest;

  /// No description provided for @tabCustom.
  ///
  /// In zh_TW, this message translates to:
  /// **'自訂義'**
  String get tabCustom;

  /// No description provided for @tabSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @greetingTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Hi，小明'**
  String get greetingTitle;

  /// No description provided for @streakLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'一週連續挑戰 第 3 天'**
  String get streakLabel;

  /// No description provided for @aiSuggest.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 飲食建議'**
  String get aiSuggest;

  /// No description provided for @latestMealTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'剛剛吃的餐點'**
  String get latestMealTitle;

  /// No description provided for @latestMealEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未有餐點紀錄'**
  String get latestMealEmpty;

  /// No description provided for @homeNextMealHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'點進建議頁，選一個最方便的方案'**
  String get homeNextMealHint;

  /// No description provided for @logTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'紀錄'**
  String get logTitle;

  /// No description provided for @dailyCalorieRange.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日熱量攝取'**
  String get dailyCalorieRange;

  /// No description provided for @dayCardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'每日摘要'**
  String get dayCardTitle;

  /// No description provided for @dayMealsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'返回本日餐次'**
  String get dayMealsTitle;

  /// No description provided for @tomorrowAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'明天建議'**
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

  /// No description provided for @summaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'將於 {time} 總結'**
  String summaryPendingAt(Object time);

  /// No description provided for @weekSummaryPendingAt.
  ///
  /// In zh_TW, this message translates to:
  /// **'將於 {day} {time} 總結'**
  String weekSummaryPendingAt(Object day, Object time);

  /// No description provided for @finalizeDay.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成今日總結'**
  String get finalizeDay;

  /// No description provided for @dishSummaryLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'本餐摘要'**
  String get dishSummaryLabel;

  /// No description provided for @mealCountEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未分析餐次'**
  String get mealCountEmpty;

  /// No description provided for @calorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未估計'**
  String get calorieUnknown;

  /// No description provided for @portionLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'份量'**
  String get portionLabel;

  /// No description provided for @portionFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'全吃'**
  String get portionFull;

  /// No description provided for @portionHalf.
  ///
  /// In zh_TW, this message translates to:
  /// **'吃一半'**
  String get portionHalf;

  /// No description provided for @portionBite.
  ///
  /// In zh_TW, this message translates to:
  /// **'只吃幾口'**
  String get portionBite;

  /// No description provided for @detailTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'詳細紀錄'**
  String get detailTitle;

  /// No description provided for @detailAiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 判斷說明'**
  String get detailAiLabel;

  /// No description provided for @detailAiEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無分析資料'**
  String get detailAiEmpty;

  /// No description provided for @detailWhyLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'為什麼這樣判斷'**
  String get detailWhyLabel;

  /// No description provided for @suggestTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'即拍建議'**
  String get suggestTitle;

  /// No description provided for @suggestInstantHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍完立即分析，提供這餐吃法建議'**
  String get suggestInstantHint;

  /// No description provided for @suggestInstantStart.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始拍照'**
  String get suggestInstantStart;

  /// No description provided for @suggestInstantRetake.
  ///
  /// In zh_TW, this message translates to:
  /// **'重新拍照'**
  String get suggestInstantRetake;

  /// No description provided for @suggestInstantPickGallery.
  ///
  /// In zh_TW, this message translates to:
  /// **'從相簿選擇'**
  String get suggestInstantPickGallery;

  /// No description provided for @suggestInstantNowEat.
  ///
  /// In zh_TW, this message translates to:
  /// **'現在吃什麼'**
  String get suggestInstantNowEat;

  /// No description provided for @suggestInstantStepDetect.
  ///
  /// In zh_TW, this message translates to:
  /// **'正在辨識餐點'**
  String get suggestInstantStepDetect;

  /// No description provided for @suggestInstantStepEstimate.
  ///
  /// In zh_TW, this message translates to:
  /// **'估算熱量與份量'**
  String get suggestInstantStepEstimate;

  /// No description provided for @suggestInstantStepAdvice.
  ///
  /// In zh_TW, this message translates to:
  /// **'產生吃法建議'**
  String get suggestInstantStepAdvice;

  /// No description provided for @suggestInstantSavePrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'要儲存這餐嗎？'**
  String get suggestInstantSavePrompt;

  /// No description provided for @suggestInstantSave.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存'**
  String get suggestInstantSave;

  /// No description provided for @suggestInstantSkipSave.
  ///
  /// In zh_TW, this message translates to:
  /// **'先不儲存'**
  String get suggestInstantSkipSave;

  /// No description provided for @suggestInstantAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'這道菜怎麼吃比較好'**
  String get suggestInstantAdviceTitle;

  /// No description provided for @suggestInstantCanEat.
  ///
  /// In zh_TW, this message translates to:
  /// **'可以吃'**
  String get suggestInstantCanEat;

  /// No description provided for @suggestInstantAvoid.
  ///
  /// In zh_TW, this message translates to:
  /// **'不建議吃'**
  String get suggestInstantAvoid;

  /// No description provided for @suggestInstantLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議份量上限'**
  String get suggestInstantLimit;

  /// No description provided for @suggestInstantMissing.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未有分析結果'**
  String get suggestInstantMissing;

  /// No description provided for @suggestInstantRecentHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議已參考最近 7 天與上一餐'**
  String get suggestInstantRecentHint;

  /// No description provided for @suggestTodayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日整體判斷'**
  String get suggestTodayLabel;

  /// No description provided for @suggestTodayHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天油脂偏高，建議下一餐清淡一點'**
  String get suggestTodayHint;

  /// No description provided for @suggestTodayOilyCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天偏油、碳水也偏多'**
  String get suggestTodayOilyCarb;

  /// No description provided for @suggestTodayOily.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天偏油，下一餐清淡一點'**
  String get suggestTodayOily;

  /// No description provided for @suggestTodayCarb.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天碳水偏多，下一餐少澱粉'**
  String get suggestTodayCarb;

  /// No description provided for @suggestTodayOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'今天狀態 OK，保持就好'**
  String get suggestTodayOk;

  /// No description provided for @logThisMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'記錄這餐'**
  String get logThisMeal;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @profileName.
  ///
  /// In zh_TW, this message translates to:
  /// **'小明'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In zh_TW, this message translates to:
  /// **'xiaoming123@gmail.com'**
  String get profileEmail;

  /// No description provided for @editProfile.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯個人資料'**
  String get editProfile;

  /// No description provided for @planSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'計畫設定'**
  String get planSection;

  /// No description provided for @heightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'身高'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'體重'**
  String get weightLabel;

  /// No description provided for @ageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'年齡'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'性別'**
  String get genderLabel;

  /// No description provided for @genderUnspecified.
  ///
  /// In zh_TW, this message translates to:
  /// **'不指定'**
  String get genderUnspecified;

  /// No description provided for @genderMale.
  ///
  /// In zh_TW, this message translates to:
  /// **'男'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh_TW, this message translates to:
  /// **'女'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In zh_TW, this message translates to:
  /// **'其他'**
  String get genderOther;

  /// No description provided for @bmiLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// No description provided for @bmiUnderweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'偏低'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In zh_TW, this message translates to:
  /// **'正常'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In zh_TW, this message translates to:
  /// **'偏高'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In zh_TW, this message translates to:
  /// **'過高'**
  String get bmiObese;

  /// No description provided for @goalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'目標'**
  String get goalLabel;

  /// No description provided for @goalLoseFat.
  ///
  /// In zh_TW, this message translates to:
  /// **'減脂降體脂'**
  String get goalLoseFat;

  /// No description provided for @reminderSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'提醒設定'**
  String get reminderSection;

  /// No description provided for @reminderLunch.
  ///
  /// In zh_TW, this message translates to:
  /// **'提醒拍攝午餐'**
  String get reminderLunch;

  /// No description provided for @reminderDinner.
  ///
  /// In zh_TW, this message translates to:
  /// **'提醒拍攝晚餐'**
  String get reminderDinner;

  /// No description provided for @subscriptionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'訂閱與其他'**
  String get subscriptionSection;

  /// No description provided for @subscriptionPlan.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前方案'**
  String get subscriptionPlan;

  /// No description provided for @planMonthly.
  ///
  /// In zh_TW, this message translates to:
  /// **'減脂周數 \$199/月'**
  String get planMonthly;

  /// No description provided for @languageLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'更換語言'**
  String get languageLabel;

  /// No description provided for @langZh.
  ///
  /// In zh_TW, this message translates to:
  /// **'繁體中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存'**
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
  /// **'維持體重'**
  String get goalMaintain;

  /// No description provided for @planSpeedLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'減脂速度'**
  String get planSpeedLabel;

  /// No description provided for @adviceStyleSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議風格'**
  String get adviceStyleSection;

  /// No description provided for @toneLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'建議語氣'**
  String get toneLabel;

  /// No description provided for @personaLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'角色視角'**
  String get personaLabel;

  /// No description provided for @toneGentle.
  ///
  /// In zh_TW, this message translates to:
  /// **'溫和'**
  String get toneGentle;

  /// No description provided for @toneDirect.
  ///
  /// In zh_TW, this message translates to:
  /// **'直接'**
  String get toneDirect;

  /// No description provided for @toneEncouraging.
  ///
  /// In zh_TW, this message translates to:
  /// **'激勵'**
  String get toneEncouraging;

  /// No description provided for @toneBullet.
  ///
  /// In zh_TW, this message translates to:
  /// **'清楚條列'**
  String get toneBullet;

  /// No description provided for @toneStrict.
  ///
  /// In zh_TW, this message translates to:
  /// **'嚴厲'**
  String get toneStrict;

  /// No description provided for @personaNutritionist.
  ///
  /// In zh_TW, this message translates to:
  /// **'營養師'**
  String get personaNutritionist;

  /// No description provided for @personaCoach.
  ///
  /// In zh_TW, this message translates to:
  /// **'外食教練'**
  String get personaCoach;

  /// No description provided for @personaFriend.
  ///
  /// In zh_TW, this message translates to:
  /// **'朋友'**
  String get personaFriend;

  /// No description provided for @personaSystem.
  ///
  /// In zh_TW, this message translates to:
  /// **'精簡系統'**
  String get personaSystem;

  /// No description provided for @summarySettingsSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'總結設定'**
  String get summarySettingsSection;

  /// No description provided for @summaryTimeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'每日總結'**
  String get summaryTimeLabel;

  /// No description provided for @weeklySummaryDayLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'每周總結'**
  String get weeklySummaryDayLabel;

  /// No description provided for @weekSummaryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'一週總結'**
  String get weekSummaryTitle;

  /// No description provided for @nextWeekAdviceTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'下週建議'**
  String get nextWeekAdviceTitle;

  /// No description provided for @weekdayMon.
  ///
  /// In zh_TW, this message translates to:
  /// **'週一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh_TW, this message translates to:
  /// **'週二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh_TW, this message translates to:
  /// **'週三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh_TW, this message translates to:
  /// **'週四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh_TW, this message translates to:
  /// **'週五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh_TW, this message translates to:
  /// **'週六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh_TW, this message translates to:
  /// **'週日'**
  String get weekdaySun;

  /// No description provided for @planSpeedStable.
  ///
  /// In zh_TW, this message translates to:
  /// **'穩定'**
  String get planSpeedStable;

  /// No description provided for @planSpeedGentle.
  ///
  /// In zh_TW, this message translates to:
  /// **'保守'**
  String get planSpeedGentle;

  /// No description provided for @activityLevelLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'預設活動量'**
  String get activityLevelLabel;

  /// No description provided for @activityLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'活動量'**
  String get activityLabel;

  /// No description provided for @activityCardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'今日活動量'**
  String get activityCardTitle;

  /// No description provided for @targetCalorieUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未估計'**
  String get targetCalorieUnknown;

  /// No description provided for @activitySedentary.
  ///
  /// In zh_TW, this message translates to:
  /// **'久坐'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In zh_TW, this message translates to:
  /// **'輕量'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In zh_TW, this message translates to:
  /// **'中度'**
  String get activityModerate;

  /// No description provided for @activityHigh.
  ///
  /// In zh_TW, this message translates to:
  /// **'高'**
  String get activityHigh;

  /// No description provided for @exerciseNoExercise.
  ///
  /// In zh_TW, this message translates to:
  /// **'無運動'**
  String get exerciseNoExercise;

  /// No description provided for @exerciseLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'運動'**
  String get exerciseLabel;

  /// No description provided for @exerciseMinutesLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'時間'**
  String get exerciseMinutesLabel;

  /// No description provided for @exerciseMinutesUnit.
  ///
  /// In zh_TW, this message translates to:
  /// **'分鐘'**
  String get exerciseMinutesUnit;

  /// No description provided for @exerciseMinutesHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入分鐘數'**
  String get exerciseMinutesHint;

  /// No description provided for @exerciseCaloriesLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'運動消耗'**
  String get exerciseCaloriesLabel;

  /// No description provided for @exerciseNone.
  ///
  /// In zh_TW, this message translates to:
  /// **'無運動'**
  String get exerciseNone;

  /// No description provided for @exerciseWalking.
  ///
  /// In zh_TW, this message translates to:
  /// **'快走'**
  String get exerciseWalking;

  /// No description provided for @exerciseJogging.
  ///
  /// In zh_TW, this message translates to:
  /// **'慢跑'**
  String get exerciseJogging;

  /// No description provided for @exerciseCycling.
  ///
  /// In zh_TW, this message translates to:
  /// **'單車'**
  String get exerciseCycling;

  /// No description provided for @exerciseSwimming.
  ///
  /// In zh_TW, this message translates to:
  /// **'游泳'**
  String get exerciseSwimming;

  /// No description provided for @exerciseStrength.
  ///
  /// In zh_TW, this message translates to:
  /// **'重量訓練'**
  String get exerciseStrength;

  /// No description provided for @exerciseYoga.
  ///
  /// In zh_TW, this message translates to:
  /// **'瑜伽'**
  String get exerciseYoga;

  /// No description provided for @exerciseHiit.
  ///
  /// In zh_TW, this message translates to:
  /// **'間歇訓練'**
  String get exerciseHiit;

  /// No description provided for @exerciseBasketball.
  ///
  /// In zh_TW, this message translates to:
  /// **'籃球'**
  String get exerciseBasketball;

  /// No description provided for @exerciseHiking.
  ///
  /// In zh_TW, this message translates to:
  /// **'登山'**
  String get exerciseHiking;

  /// No description provided for @deltaUnknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未估計'**
  String get deltaUnknown;

  /// No description provided for @deltaOk.
  ///
  /// In zh_TW, this message translates to:
  /// **'接近目標'**
  String get deltaOk;

  /// No description provided for @deltaSurplus.
  ///
  /// In zh_TW, this message translates to:
  /// **'超出 {kcal} kcal'**
  String deltaSurplus(int kcal);

  /// No description provided for @deltaDeficit.
  ///
  /// In zh_TW, this message translates to:
  /// **'赤字 {kcal} kcal'**
  String deltaDeficit(int kcal);

  /// No description provided for @reminderLunchTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'午餐提醒時間'**
  String get reminderLunchTime;

  /// No description provided for @reminderDinnerTime.
  ///
  /// In zh_TW, this message translates to:
  /// **'晚餐提醒時間'**
  String get reminderDinnerTime;

  /// No description provided for @pickFromCamera.
  ///
  /// In zh_TW, this message translates to:
  /// **'拍照'**
  String get pickFromCamera;

  /// No description provided for @pickFromGallery.
  ///
  /// In zh_TW, this message translates to:
  /// **'從相簿選擇'**
  String get pickFromGallery;

  /// No description provided for @addMeal.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增'**
  String get addMeal;

  /// No description provided for @noMealPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未紀錄，拍一張也可以'**
  String get noMealPrompt;

  /// No description provided for @layoutThemeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'主題與版面'**
  String get layoutThemeLabel;

  /// No description provided for @textSizeLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'字體大小'**
  String get textSizeLabel;

  /// No description provided for @textSizeSmall.
  ///
  /// In zh_TW, this message translates to:
  /// **'標準'**
  String get textSizeSmall;

  /// No description provided for @textSizeMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'偏大'**
  String get textSizeMedium;

  /// No description provided for @textSizeLarge.
  ///
  /// In zh_TW, this message translates to:
  /// **'特大'**
  String get textSizeLarge;

  /// No description provided for @themeClean.
  ///
  /// In zh_TW, this message translates to:
  /// **'清爽藍'**
  String get themeClean;

  /// No description provided for @glowToggleLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'柔光背景'**
  String get glowToggleLabel;

  /// No description provided for @themeGreen.
  ///
  /// In zh_TW, this message translates to:
  /// **'清爽綠'**
  String get themeGreen;

  /// No description provided for @themeWarm.
  ///
  /// In zh_TW, this message translates to:
  /// **'暖橘'**
  String get themeWarm;

  /// No description provided for @themePink.
  ///
  /// In zh_TW, this message translates to:
  /// **'柔粉'**
  String get themePink;

  /// No description provided for @plateSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'盤子樣式'**
  String get plateSection;

  /// No description provided for @plateStyleLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'盤子款式'**
  String get plateStyleLabel;

  /// No description provided for @plateDefaultLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'預設瓷盤'**
  String get plateDefaultLabel;

  /// No description provided for @plateWarmLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'暖色陶瓷盤'**
  String get plateWarmLabel;

  /// No description provided for @apiSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'API 連線'**
  String get apiSection;

  /// No description provided for @apiBaseUrlLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'API 位址'**
  String get apiBaseUrlLabel;

  /// No description provided for @delete.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要刪除此紀錄嗎？'**
  String get deleteConfirm;

  /// No description provided for @logSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'已記錄這餐'**
  String get logSuccess;

  /// No description provided for @viewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'查看紀錄'**
  String get viewLog;

  /// No description provided for @calories.
  ///
  /// In zh_TW, this message translates to:
  /// **'熱量'**
  String get calories;

  /// No description provided for @estimated.
  ///
  /// In zh_TW, this message translates to:
  /// **'估計'**
  String get estimated;

  /// No description provided for @protein.
  ///
  /// In zh_TW, this message translates to:
  /// **'蛋白質'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In zh_TW, this message translates to:
  /// **'碳水'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In zh_TW, this message translates to:
  /// **'脂肪'**
  String get fat;

  /// No description provided for @sodium.
  ///
  /// In zh_TW, this message translates to:
  /// **'鈉含量'**
  String get sodium;

  /// No description provided for @tier.
  ///
  /// In zh_TW, this message translates to:
  /// **'層級'**
  String get tier;

  /// No description provided for @analyzeFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'分析失敗'**
  String get analyzeFailed;

  /// No description provided for @costEstimateLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'估算花費'**
  String get costEstimateLabel;

  /// No description provided for @usageSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 花費'**
  String get usageSection;

  /// No description provided for @usageTotalLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'累計花費'**
  String get usageTotalLabel;

  /// No description provided for @usageViewLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'查看紀錄'**
  String get usageViewLog;

  /// No description provided for @usageEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無花費紀錄'**
  String get usageEmpty;

  /// No description provided for @usageLoading.
  ///
  /// In zh_TW, this message translates to:
  /// **'載入中...'**
  String get usageLoading;

  /// No description provided for @mockPrefix.
  ///
  /// In zh_TW, this message translates to:
  /// **'模擬'**
  String get mockPrefix;

  /// No description provided for @versionSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'版本資訊'**
  String get versionSection;

  /// No description provided for @versionBuild.
  ///
  /// In zh_TW, this message translates to:
  /// **'更新時間'**
  String get versionBuild;

  /// No description provided for @versionCommit.
  ///
  /// In zh_TW, this message translates to:
  /// **'版本代碼'**
  String get versionCommit;

  /// No description provided for @versionUnavailable.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法取得版本資訊'**
  String get versionUnavailable;

  /// No description provided for @nutritionChartLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'營養圖表'**
  String get nutritionChartLabel;

  /// No description provided for @nutritionValueLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'營養顯示'**
  String get nutritionValueLabel;

  /// No description provided for @nutritionValuePercent.
  ///
  /// In zh_TW, this message translates to:
  /// **'百分比'**
  String get nutritionValuePercent;

  /// No description provided for @nutritionValueAmount.
  ///
  /// In zh_TW, this message translates to:
  /// **'數值'**
  String get nutritionValueAmount;

  /// No description provided for @chartRadar.
  ///
  /// In zh_TW, this message translates to:
  /// **'雷達圖'**
  String get chartRadar;

  /// No description provided for @chartBars.
  ///
  /// In zh_TW, this message translates to:
  /// **'條狀圖'**
  String get chartBars;

  /// No description provided for @chartDonut.
  ///
  /// In zh_TW, this message translates to:
  /// **'圓環圖'**
  String get chartDonut;

  /// No description provided for @dataSection.
  ///
  /// In zh_TW, this message translates to:
  /// **'資料管理'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯出資料'**
  String get exportData;

  /// No description provided for @clearData.
  ///
  /// In zh_TW, this message translates to:
  /// **'清除資料'**
  String get clearData;

  /// No description provided for @clearDataConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要清除所有資料嗎？'**
  String get clearDataConfirm;

  /// No description provided for @exportDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'已匯出'**
  String get exportDone;

  /// No description provided for @clearDone.
  ///
  /// In zh_TW, this message translates to:
  /// **'已清除'**
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
