// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '飲食 AI MVP';

  @override
  String get takePhoto => '拍照紀錄';

  @override
  String get uploadPhoto => '上傳照片';

  @override
  String get quickAdd => '快速新增（自動分餐）';

  @override
  String get breakfast => '早餐';

  @override
  String get brunch => '早午餐';

  @override
  String get lunch => '中餐';

  @override
  String get afternoonTea => '下午茶';

  @override
  String get dinner => '晚餐';

  @override
  String get lateSnack => '消夜';

  @override
  String get other => '其他';

  @override
  String get timeLabel => '時間';

  @override
  String get editTime => '修改時間';

  @override
  String get noEntries => '尚無紀錄';

  @override
  String get mealTotal => '本餐估計熱量';

  @override
  String get mealSummaryTitle => '菜色摘要';

  @override
  String get todayMeals => '今日餐點';

  @override
  String itemsCount(int count) {
    return '$count 筆';
  }

  @override
  String get captureTitle => '拍照紀錄';

  @override
  String get captureHint => '拍下你正在吃的餐點即可';

  @override
  String get optionalNoteLabel => '補充說明（可選）';

  @override
  String get notePlaceholder => '例如：只吃一半、打包帶走';

  @override
  String get recentPhotos => '最近照片';

  @override
  String get noPhotos => '尚未新增照片';

  @override
  String get analysisTitle => '餐點分析';

  @override
  String get analysisEmpty => '還沒有分析內容，先拍一張吧';

  @override
  String get foodNameLabel => '食物名稱';

  @override
  String get editFoodName => '修改食物名稱';

  @override
  String get reanalyzeLabel => '重新分析';

  @override
  String get addLabel => '補充標示';

  @override
  String get removeLabel => '移除標示';

  @override
  String get labelInfoTitle => '标示資訊';

  @override
  String get labelSummaryFallback => '已採用標示資訊';

  @override
  String get customTabTitle => '自訂義';

  @override
  String get customAdd => '加入自訂義';

  @override
  String get customAdded => '已加入自訂義';

  @override
  String get customEmpty => '目前沒有自訂義項目';

  @override
  String get customSelectTitle => '選擇自訂義';

  @override
  String get customConfirmTitle => '確認餐別與時間';

  @override
  String get customConfirmDate => '日期';

  @override
  String get customConfirmTime => '時間';

  @override
  String get customConfirmMealType => '餐別';

  @override
  String get customUse => '使用自訂義';

  @override
  String get customUseSaved => '已儲存自訂義餐點';

  @override
  String get customCountUnit => '筆';

  @override
  String get customEditTitle => '編輯自訂義';

  @override
  String get customChangePhoto => '更換照片';

  @override
  String get customSummaryLabel => '菜色摘要';

  @override
  String get customSuggestionLabel => '建議';

  @override
  String get customDeleteTitle => '刪除自訂義';

  @override
  String get customDeleteConfirm => '確定刪除這個自訂義？';

  @override
  String get unknownFood => '未命名餐點';

  @override
  String get dietitianPrefix => '建議：';

  @override
  String get dietitianBalanced => '整體均衡，維持即可。';

  @override
  String get dietitianProteinLow => '蛋白質偏低，建議補豆魚蛋肉。';

  @override
  String get dietitianFatHigh => '油脂偏高，下一餐清淡少油。';

  @override
  String get dietitianCarbHigh => '碳水偏多，主食減量。';

  @override
  String get dietitianSodiumHigh => '鈉含量偏高，減少湯底與加工品。';

  @override
  String get multiItemsLabel => '多品项';

  @override
  String get goalAdviceLoseFat => '以減脂為目標，下一餐以蛋白質與蔬菜為主。';

  @override
  String get goalAdviceMaintain => '以維持為主，注意份量與均衡。';

  @override
  String get overallLabel => '整體判斷';

  @override
  String get calorieLabel => '熱量區間';

  @override
  String get editCalorieTitle => '編輯熱量';

  @override
  String get editCalorieHint => '例如 450-600 kcal';

  @override
  String get editCalorieClear => '清除';

  @override
  String get macroLabel => '三大營養';

  @override
  String get levelLow => '低';

  @override
  String get levelMedium => '中';

  @override
  String get levelHigh => '高';

  @override
  String get statusOk => 'OK';

  @override
  String get statusWarn => '偏多';

  @override
  String get statusOver => '爆';

  @override
  String get tagOily => '偏油';

  @override
  String get tagProteinOk => '蛋白質足';

  @override
  String get tagProteinLow => '蛋白質不足';

  @override
  String get tagCarbHigh => '碳水偏多';

  @override
  String get tagOk => 'OK';

  @override
  String get nextMealTitle => '下一餐建議怎麼吃';

  @override
  String get nextMealSectionTitle => '下一餐建議怎麼吃';

  @override
  String get noLateSnackSelfCook => '不建議消夜；若想吃，清湯蔬菜小份';

  @override
  String get noLateSnackConvenience => '不建議消夜；若想吃，無糖豆漿或小份沙拉';

  @override
  String get noLateSnackBento => '不建議消夜；若想吃，半份蔬菜便當';

  @override
  String get noLateSnackOther => '不建議消夜；若想吃，少量水果即可';

  @override
  String get nextMealHint => '選一個最方便的方式就好';

  @override
  String get nextSelfCookLabel => '自煮';

  @override
  String get nextConvenienceLabel => '便利店';

  @override
  String get nextBentoLabel => '便當';

  @override
  String get nextOtherLabel => '其他';

  @override
  String get nextSelfCookHint => '清蒸/水煮＋蔬菜，少油少醬';

  @override
  String get nextConvenienceHint => '茶葉蛋/無糖豆漿/沙拉，少炸物';

  @override
  String get nextBentoHint => '半飯、多菜、優先烤或滷';

  @override
  String get nextOtherHint => '水果/無糖優格/清湯';

  @override
  String get mealItemsTitle => '返回本餐';

  @override
  String get mealTimeSection => '餐次區間';

  @override
  String get breakfastStartLabel => '早餐開始';

  @override
  String get breakfastEndLabel => '早餐結束';

  @override
  String get brunchStartLabel => '早午餐開始';

  @override
  String get brunchEndLabel => '早午餐結束';

  @override
  String get lunchStartLabel => '午餐開始';

  @override
  String get lunchEndLabel => '午餐結束';

  @override
  String get afternoonTeaStartLabel => '下午茶開始';

  @override
  String get afternoonTeaEndLabel => '下午茶結束';

  @override
  String get dinnerStartLabel => '晚餐開始';

  @override
  String get dinnerEndLabel => '晚餐結束';

  @override
  String get lateSnackStartLabel => '消夜開始';

  @override
  String get lateSnackEndLabel => '消夜結束';

  @override
  String get optionConvenienceTitle => '便利商店';

  @override
  String get optionConvenienceDesc => '選茶葉蛋/無糖豆漿/沙拉，少炸物';

  @override
  String get optionBentoTitle => '便當店';

  @override
  String get optionBentoDesc => '半飯、多蔬菜、優先選烤或滷';

  @override
  String get optionLightTitle => '清淡選擇';

  @override
  String get optionLightDesc => '清湯、蒸煮、少醬料';

  @override
  String get summaryTitle => '今日總結';

  @override
  String get summaryEmpty => '今天還沒記錄餐點喔';

  @override
  String get summaryOilyCarb => '今天偏油、碳水也偏多';

  @override
  String get summaryOily => '今天偏油';

  @override
  String get summaryCarb => '今天碳水偏多';

  @override
  String get summaryProteinOk => '蛋白質 OK，記得補點蔬菜';

  @override
  String get summaryNeutral => '今天狀態不錯，繼續保持';

  @override
  String get summaryBeverageOnly => '今天只記錄了飲料';

  @override
  String get includesBeverages => '含飲料';

  @override
  String get proteinIntakeTodayLabel => '今日蛋白質';

  @override
  String proteinIntakeFormat(int consumed, int min, int max) {
    return '已攝取 ${consumed}g / 目標 $min-${max}g';
  }

  @override
  String get smallPortionNote => '份量不多';

  @override
  String get mealsCountLabel => '已記錄';

  @override
  String get mealsLabel => '餐';

  @override
  String get tabCapture => '拍照';

  @override
  String get tabAnalysis => '分析';

  @override
  String get tabNext => '下一餐';

  @override
  String get tabSummary => '摘要';

  @override
  String get tabHome => '首頁';

  @override
  String get tabLog => '紀錄';

  @override
  String get tabSuggest => '即拍建議';

  @override
  String get tabCustom => '自訂義';

  @override
  String get tabSettings => '設定';

  @override
  String greetingTitle(String name) {
    return '嗨 $name，今天也加油';
  }

  @override
  String streakLabel(int count) {
    return '已連續紀錄 $count 天';
  }

  @override
  String get aiSuggest => 'AI 飲食建議';

  @override
  String get latestMealTitle => '剛剛吃的餐點';

  @override
  String get latestMealEmpty => '今天還沒記錄餐點喔';

  @override
  String get homeNextMealHint => '點進建議頁，挑一個最順手的方案';

  @override
  String get logTitle => '紀錄';

  @override
  String get logTopMealTitle => '熱量最高一餐';

  @override
  String get logTopMealEmpty => '近 7 天尚未有完整紀錄';

  @override
  String logRecentDaysTag(String date) {
    return '近 7 天 $date';
  }

  @override
  String get logAddMealPrompt => '補記這一餐';

  @override
  String get dailyCalorieRange => '今日熱量攝取';

  @override
  String get dayCardTitle => '每日摘要';

  @override
  String get dayMealsTitle => '返回本日餐次';

  @override
  String get tomorrowAdviceTitle => '明天建議';

  @override
  String get dayCardDateLabel => '日期：';

  @override
  String get dayCardCalorieLabel => '今日熱量攝取';

  @override
  String get dayCardMealsLabel => '分析餐數：';

  @override
  String get dayCardSummaryLabel => '今日總結';

  @override
  String get dayCardTomorrowLabel => '明日建議';

  @override
  String summaryPendingAt(Object time) {
    return '將於 $time 產生總結';
  }

  @override
  String weekSummaryPendingAt(Object day, Object time) {
    return '將於 $day $time 產生總結';
  }

  @override
  String get finalizeDay => '生成今日總結';

  @override
  String get dishSummaryLabel => '本餐摘要';

  @override
  String get mealCountEmpty => '尚未分析餐次';

  @override
  String get calorieUnknown => '目前還沒有估算結果';

  @override
  String get portionLabel => '份量';

  @override
  String get portionFull => '全吃';

  @override
  String get portionHalf => '吃一半';

  @override
  String get portionBite => '只吃幾口';

  @override
  String get detailTitle => '詳細紀錄';

  @override
  String get detailAiLabel => 'AI 判斷說明';

  @override
  String get detailAiEmpty => '尚無分析資料';

  @override
  String get detailWhyLabel => '為什麼這樣判斷';

  @override
  String get suggestTitle => '即拍建議';

  @override
  String get suggestInstantHint => '拍完馬上分析，給你這餐吃法建議';

  @override
  String get suggestInstantStart => '開始拍照';

  @override
  String get suggestInstantRetake => '拍下一張';

  @override
  String get suggestInstantPickGallery => '從相簿選擇';

  @override
  String get suggestInstantNowEat => '建議我吃什麼';

  @override
  String get suggestInstantNameHint => '輸入食物名稱（沒有照片也可以）';

  @override
  String get suggestInstantNameSubmit => '送出';

  @override
  String get nameAnalyzeStart => '正在分析';

  @override
  String get nameAnalyzeEmpty => '請輸入食物名稱';

  @override
  String get suggestInstantStepDetect => '正在辨識餐點';

  @override
  String get suggestInstantStepEstimate => '估算熱量與份量';

  @override
  String get suggestInstantStepAdvice => '產生吃法建議';

  @override
  String get suggestInstantSavePrompt => '要儲存這餐嗎？';

  @override
  String get suggestInstantSave => '儲存';

  @override
  String get suggestInstantSkipSave => '先不儲存';

  @override
  String get suggestInstantAdviceTitle => '这份食物怎么吃比较好';

  @override
  String get suggestInstantCanEat => '搭配';

  @override
  String get suggestInstantCanDrink => '可以喝';

  @override
  String get suggestInstantAvoid => '不建议';

  @override
  String get suggestInstantAvoidDrink => '不建议喝';

  @override
  String get suggestInstantLimit => '建议份量';

  @override
  String get suggestInstantDrinkLimit => '建议份量';

  @override
  String get suggestInstantDrinkAdviceTitle => '这杯饮料怎么喝比较好';

  @override
  String get suggestInstantCanEatInline => '可以怎么吃';

  @override
  String get suggestInstantRiskInline => '可能会有的问题';

  @override
  String get suggestInstantLimitInline => '建议份量';

  @override
  String get suggestInstantEnergyOk => '可接受';

  @override
  String get suggestInstantEnergyHigh => '偏高';

  @override
  String get suggestInstantMissing => '還沒有分析結果';

  @override
  String get suggestInstantNonFood => '这不是食物，请重拍。若现在不打算吃东西，也欢迎之后肚子饿再使用。';

  @override
  String get suggestInstantReestimate => '重新估算';

  @override
  String get suggestInstantRecentHint => '建議已參考最近 7 天與上一餐';

  @override
  String get suggestAutoSaved => '已自動儲存';

  @override
  String get suggestTodayLabel => '今日整體判斷';

  @override
  String get suggestTodayHint => '今天油脂偏高，下一餐清淡一點';

  @override
  String get suggestTodayOilyCarb => '今天偏油、碳水也偏多';

  @override
  String get suggestTodayOily => '今天偏油，下一餐清淡一點';

  @override
  String get suggestTodayCarb => '今天碳水偏多，下一餐少澱粉';

  @override
  String get suggestTodayOk => '今天狀態不錯，保持就好';

  @override
  String get logThisMeal => '記錄這餐';

  @override
  String get settingsTitle => '設定';

  @override
  String get profileName => '小明';

  @override
  String get profileEmail => 'xiaoming123@gmail.com';

  @override
  String get editProfile => '編輯個人資料';

  @override
  String get nicknameLabel => '暱稱';

  @override
  String get planSection => '計畫設定';

  @override
  String get heightLabel => '身高';

  @override
  String get weightLabel => '體重';

  @override
  String get ageLabel => '年齡';

  @override
  String get genderLabel => '性別';

  @override
  String get genderUnspecified => '不指定';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderOther => '其他';

  @override
  String get bmiLabel => 'BMI';

  @override
  String get bmiUnderweight => '偏低';

  @override
  String get bmiNormal => '正常';

  @override
  String get bmiOverweight => '偏高';

  @override
  String get bmiObese => '過高';

  @override
  String get goalLabel => '目標';

  @override
  String get goalLoseFat => '減脂降體脂';

  @override
  String get reminderSection => '提醒設定';

  @override
  String get reminderLunch => '提醒拍攝午餐';

  @override
  String get reminderDinner => '提醒拍攝晚餐';

  @override
  String get subscriptionSection => '訂閱與其他';

  @override
  String get subscriptionPlan => '目前方案';

  @override
  String get webTestSectionTitle => 'Web 測試';

  @override
  String get webTestSubscriptionLabel => '測試訂閱';

  @override
  String get webTestEnabled => '已啟用';

  @override
  String get webTestDisabled => '未啟用';

  @override
  String get webTestPlanMonthly => '月訂（測試）';

  @override
  String get webTestPlanYearly => '年訂（測試）';

  @override
  String get webTestPlanNone => '未訂閱';

  @override
  String get webTestAccessGraceLabel => '驗證寬限時間';

  @override
  String get webTestAccessGraceDialogTitle => '驗證寬限時間（1-168 小時）';

  @override
  String webTestAccessGraceValue(int hours) {
    return '$hours 小時';
  }

  @override
  String get accessStatusFailed => '驗證失敗，請稍後再試';

  @override
  String get planMonthly => '減脂周數 \$199/月';

  @override
  String get languageLabel => '更換語言';

  @override
  String get langZh => '繁體中文';

  @override
  String get langEn => 'English';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get edit => '編輯';

  @override
  String get editDaySummaryTitle => '編輯今日摘要';

  @override
  String get editMealAdviceTitle => '編輯下一餐建議';

  @override
  String get goalMaintain => '維持體重';

  @override
  String get planSpeedLabel => '減脂速度';

  @override
  String get adviceStyleSection => '建議風格';

  @override
  String get toneLabel => '建議語氣';

  @override
  String get personaLabel => '角色視角';

  @override
  String get toneGentle => '溫和';

  @override
  String get toneDirect => '直接';

  @override
  String get toneEncouraging => '激勵';

  @override
  String get toneBullet => '清楚條列';

  @override
  String get toneStrict => '嚴厲';

  @override
  String get personaNutritionist => '營養師';

  @override
  String get personaCoach => '外食教練';

  @override
  String get personaFriend => '朋友';

  @override
  String get personaSystem => '精簡系統';

  @override
  String get summarySettingsSection => '總結設定';

  @override
  String get summaryTimeLabel => '每日總結';

  @override
  String get weeklySummaryDayLabel => '每周總結';

  @override
  String get weekTopMealTitle => '本週熱量最高一餐';

  @override
  String get recentGuidanceTitle => '近期方針（近 7 天）';

  @override
  String get weekSummaryTitle => '本週總結';

  @override
  String get nextWeekAdviceTitle => '下週建議';

  @override
  String get weekdayMon => '週一';

  @override
  String get weekdayTue => '週二';

  @override
  String get weekdayWed => '週三';

  @override
  String get weekdayThu => '週四';

  @override
  String get weekdayFri => '週五';

  @override
  String get weekdaySat => '週六';

  @override
  String get weekdaySun => '週日';

  @override
  String get planSpeedStable => '穩定';

  @override
  String get planSpeedGentle => '保守';

  @override
  String get activityLevelLabel => '預設活動量';

  @override
  String get activityLabel => '活動量';

  @override
  String get activityCardTitle => '今日活動量';

  @override
  String get targetCalorieUnknown => '尚未估計';

  @override
  String get activitySedentary => '久坐';

  @override
  String get activityLight => '輕量';

  @override
  String get activityModerate => '中度';

  @override
  String get activityHigh => '高';

  @override
  String get exerciseNoExercise => '無運動';

  @override
  String get exerciseLabel => '運动';

  @override
  String get exerciseMinutesLabel => '时间';

  @override
  String get exerciseMinutesUnit => '分钟';

  @override
  String get exerciseMinutesHint => '输入分钟数';

  @override
  String get exerciseCaloriesLabel => '运动消耗';

  @override
  String get exerciseNone => '無運動';

  @override
  String get exerciseWalking => '快走';

  @override
  String get exerciseJogging => '慢跑';

  @override
  String get exerciseCycling => '单车';

  @override
  String get exerciseSwimming => '游泳';

  @override
  String get exerciseStrength => '重量训练';

  @override
  String get exerciseYoga => '瑜伽';

  @override
  String get exerciseHiit => '间歇训练';

  @override
  String get exerciseBasketball => '篮球';

  @override
  String get exerciseHiking => '登山';

  @override
  String get deltaUnknown => '尚未估计';

  @override
  String get deltaOk => '接近目标';

  @override
  String deltaSurplus(int kcal) {
    return '超出 $kcal kcal';
  }

  @override
  String deltaDeficit(int kcal) {
    return '赤字 $kcal kcal';
  }

  @override
  String get commonExerciseLabel => '常用運動';

  @override
  String get suggestRemainingTitle => '今天還能吃多少';

  @override
  String suggestRemainingLeft(int cal) {
    return '還可以吃 $cal kcal';
  }

  @override
  String suggestRemainingOver(int cal) {
    return '已超過 $cal kcal';
  }

  @override
  String suggestExerciseHint(String exercise, int minutes) {
    return '建議做 $exercise 約 $minutes 分鐘';
  }

  @override
  String get reminderLunchTime => '午餐提醒時間';

  @override
  String get reminderDinnerTime => '晚餐提醒時間';

  @override
  String get pickFromCamera => '拍照';

  @override
  String get pickFromGallery => '從相簿選擇';

  @override
  String get addMeal => '新增';

  @override
  String get noMealPrompt => '尚未紀錄，拍一張也可以';

  @override
  String get layoutThemeLabel => '主題與版面';

  @override
  String get textSizeLabel => '字體大小';

  @override
  String get textSizeSmall => '標準';

  @override
  String get textSizeMedium => '偏大';

  @override
  String get textSizeLarge => '特大';

  @override
  String get themeClean => '清爽藍';

  @override
  String get glowToggleLabel => '柔光背景';

  @override
  String get themeGreen => '清爽綠';

  @override
  String get themeWarm => '暖橘';

  @override
  String get themePink => '柔粉';

  @override
  String get plateSection => '盤子樣式';

  @override
  String get plateStyleLabel => '盤子款式';

  @override
  String get plateDefaultLabel => '預設瓷盤';

  @override
  String get plateWarmLabel => '暖色陶瓷盤';

  @override
  String get apiSection => 'API 連線';

  @override
  String get apiBaseUrlLabel => 'API 位址';

  @override
  String get delete => '刪除';

  @override
  String get deleteConfirm => '確定要刪除此紀錄嗎？';

  @override
  String get logSuccess => '已記錄這餐';

  @override
  String get viewLog => '查看紀錄';

  @override
  String get calories => '熱量';

  @override
  String get estimated => 'AI 估算';

  @override
  String get protein => '蛋白質';

  @override
  String get carbs => '碳水';

  @override
  String get fat => '脂肪';

  @override
  String get sodium => '鈉含量';

  @override
  String get tier => '層級';

  @override
  String get analyzeFailed => '目前無法分析';

  @override
  String get costEstimateLabel => '估算花費';

  @override
  String get usageSection => 'AI 花費';

  @override
  String get usageTotalLabel => '累計花費';

  @override
  String get usageViewLog => '查看紀錄';

  @override
  String get usageEmpty => '尚無花費紀錄';

  @override
  String get usageLoading => '載入中...';

  @override
  String get mockPrefix => '預覽';

  @override
  String get versionSection => '版本資訊';

  @override
  String get versionBuild => '更新時間';

  @override
  String get versionCommit => '版本代碼';

  @override
  String get versionUnavailable => '無法取得版本資訊';

  @override
  String get nutritionChartLabel => '營養圖表';

  @override
  String get nutritionValueLabel => '營養顯示';

  @override
  String get nutritionValuePercent => '百分比';

  @override
  String get nutritionValueAmount => '數值';

  @override
  String get chartRadar => '雷達圖';

  @override
  String get chartBars => '條狀圖';

  @override
  String get chartDonut => '圓環圖';

  @override
  String get dataSection => '資料管理';

  @override
  String get syncSection => '帳號與同步';

  @override
  String get syncSignedInAs => '已登入：';

  @override
  String get syncNotSignedIn => '尚未登入';

  @override
  String get syncEmailLabel => 'Email';

  @override
  String get syncPasswordLabel => '密碼';

  @override
  String get syncSignIn => '登入';

  @override
  String get syncSignUp => '註冊';

  @override
  String get syncSignUpSuccess => '已寄送驗證信，請先完成信箱驗證';

  @override
  String get syncSignInSuccess => '登入成功';

  @override
  String get syncForgotPassword => '忘記密碼';

  @override
  String get syncResetPasswordTitle => '重設密碼';

  @override
  String get syncResetPasswordHint => '輸入註冊信箱';

  @override
  String get syncResetPasswordSent => '已寄送重設密碼郵件';

  @override
  String get syncSignOut => '登出';

  @override
  String get syncUpload => '上傳同步';

  @override
  String get syncDownload => '下載同步';

  @override
  String get syncNow => '同步';

  @override
  String get syncInProgress => '正在努力同步中…';

  @override
  String get syncSuccess => '同步完成囉';

  @override
  String get syncUpdated => '更新完成';

  @override
  String get syncNoChanges => '目前沒有要同步的資料';

  @override
  String get syncError => '同步失敗，請稍後再試';

  @override
  String get syncRequireLogin => '先登入才能同步喔';

  @override
  String get syncAuthTitleSignIn => '登入帳號';

  @override
  String get syncAuthTitleSignUp => '註冊帳號';

  @override
  String get exportData => '匯出資料';

  @override
  String get clearData => '清除資料';

  @override
  String get clearDataConfirm => '確定要清除所有資料嗎？';

  @override
  String get exportDone => '已匯出';

  @override
  String get clearDone => '已清除';

  @override
  String get close => '關閉';

  @override
  String get authTitle => '歡迎使用 Food AI';

  @override
  String get authSubtitle => '登入後即可使用完整功能';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => '請輸入 Email';

  @override
  String get authEmailInvalid => 'Email 格式不正確';

  @override
  String get authPasswordLabel => '密碼';

  @override
  String get authConfirmPasswordLabel => '確認密碼';

  @override
  String get authSignIn => '登入';

  @override
  String get authSignUp => '註冊';

  @override
  String get authToggleToSignUp => '沒有帳號？立即註冊';

  @override
  String get authToggleToSignIn => '已有帳號？返回登入';

  @override
  String get authForgotPassword => '忘記密碼';

  @override
  String get authSignInSuccess => '登入成功';

  @override
  String get authSignUpSuccess => '註冊完成';

  @override
  String get authSignUpVerify => '註冊完成，請前往信箱完成驗證';

  @override
  String get authEmailNotVerified => '此 Email 尚未驗證，請先完成信箱驗證';

  @override
  String get authVerifyTitle => '請驗證信箱';

  @override
  String authVerifyBody(String email) {
    return '我們已寄送驗證信到 $email，請在 1-3 分鐘內查看，也請檢查垃圾郵件/促銷匣。';
  }

  @override
  String get authResend => '重新寄送驗證信';

  @override
  String authResendCooldown(int seconds) {
    return '重新寄送（${seconds}s）';
  }

  @override
  String get authResendSent => '驗證信已重新寄出';

  @override
  String get authResendFailed => '重新寄送失敗，請稍後再試';

  @override
  String get authTooManyAttempts => '請稍後再試';

  @override
  String get authPasswordMismatch => '兩次密碼不一致';

  @override
  String get authPasswordRule => '密碼至少 8 碼，且不可含空白或中文';

  @override
  String get authPasswordInvalid => '密碼需至少 8 碼，且不可含空白或中文';

  @override
  String get authResetSent => '重設密碼信已寄出，請查看信箱';

  @override
  String get authResetFailed => '重設失敗，請確認 Email 是否正確';

  @override
  String get authLoginInvalid => 'Email 或密碼錯誤';

  @override
  String get authEmailExists => '此 Email 已註冊';

  @override
  String get authNetworkError => '連線異常，請稍後再試';

  @override
  String get authSignUpFailed => '註冊失敗';

  @override
  String get authError => '登入失敗，請稍後再試';

  @override
  String get trialExpiredTitle => '試用期已結束';

  @override
  String get trialExpiredBody => '你已完成 2 天免費試用，請訂閱後繼續使用 AI 分析功能。';

  @override
  String get trialExpiredAction => '了解方案';

  @override
  String get signOut => '登出';

  @override
  String get dietPreferenceSection => '饮食偏好';

  @override
  String get dietTypeLabel => '饮食类型';

  @override
  String get dietNoteLabel => '偏好补充';

  @override
  String get dietTypeNone => '不限制';

  @override
  String get dietTypeVegetarian => '奶蛋素';

  @override
  String get dietTypeVegan => '全素';

  @override
  String get dietTypePescatarian => '海鲜素';

  @override
  String get dietTypeLowCarb => '低碳';

  @override
  String get dietTypeKeto => '生酮';

  @override
  String get dietTypeLowFat => '低脂';

  @override
  String get dietTypeHighProtein => '高蛋白';

  @override
  String get authNicknameRequired => '请输入昵称';

  @override
  String get containerSection => '常用容器';

  @override
  String get containerTypeLabel => '容器类型';

  @override
  String get containerSizeLabel => '容器尺寸';

  @override
  String get containerDepthLabel => '碗深度';

  @override
  String get containerDiameterLabel => '直径 (cm)';

  @override
  String get containerCapacityLabel => '容量 (ml)';

  @override
  String get containerTypeBowl => '碗';

  @override
  String get containerTypePlate => '盘';

  @override
  String get containerTypeBox => '便当盒';

  @override
  String get containerTypeCup => '杯';

  @override
  String get containerTypeUnknown => '不指定';

  @override
  String get containerSizeSmall => '小';

  @override
  String get containerSizeMedium => '中';

  @override
  String get containerSizeLarge => '大';

  @override
  String get containerSizeStandard => '标准';

  @override
  String get containerSizeCustom => '自订';

  @override
  String get containerDepthShallow => '浅';

  @override
  String get containerDepthMedium => '中';

  @override
  String get containerDepthDeep => '深';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '飲食 AI MVP';

  @override
  String get takePhoto => '拍照紀錄';

  @override
  String get uploadPhoto => '上傳照片';

  @override
  String get quickAdd => '快速新增（自動分餐）';

  @override
  String get breakfast => '早餐';

  @override
  String get brunch => '早午餐';

  @override
  String get lunch => '中餐';

  @override
  String get afternoonTea => '下午茶';

  @override
  String get dinner => '晚餐';

  @override
  String get lateSnack => '消夜';

  @override
  String get other => '其他';

  @override
  String get timeLabel => '時間';

  @override
  String get editTime => '修改時間';

  @override
  String get noEntries => '尚無紀錄';

  @override
  String get mealTotal => '本餐估計熱量';

  @override
  String get mealSummaryTitle => '菜色摘要';

  @override
  String get todayMeals => '今日餐點';

  @override
  String itemsCount(int count) {
    return '$count 筆';
  }

  @override
  String get captureTitle => '拍照紀錄';

  @override
  String get captureHint => '拍下你正在吃的餐點即可';

  @override
  String get optionalNoteLabel => '補充說明（可選）';

  @override
  String get notePlaceholder => '例如：只吃一半、打包帶走';

  @override
  String get recentPhotos => '最近照片';

  @override
  String get noPhotos => '尚未新增照片';

  @override
  String get analysisTitle => '餐點分析';

  @override
  String get analysisEmpty => '還沒有分析內容，先拍一張吧';

  @override
  String get foodNameLabel => '食物名稱';

  @override
  String get editFoodName => '修改食物名稱';

  @override
  String get reanalyzeLabel => '重新分析';

  @override
  String get addLabel => '補充標示';

  @override
  String get removeLabel => '移除標示';

  @override
  String get labelInfoTitle => '標示資訊';

  @override
  String get labelSummaryFallback => '已採用標示資訊';

  @override
  String get customTabTitle => '自訂義';

  @override
  String get customAdd => '加入自訂義';

  @override
  String get customAdded => '已加入自訂義';

  @override
  String get customEmpty => '目前沒有自訂義項目';

  @override
  String get customSelectTitle => '選擇自訂義';

  @override
  String get customConfirmTitle => '確認餐別與時間';

  @override
  String get customConfirmDate => '日期';

  @override
  String get customConfirmTime => '時間';

  @override
  String get customConfirmMealType => '餐別';

  @override
  String get customUse => '使用自訂義';

  @override
  String get customUseSaved => '已儲存自訂義餐點';

  @override
  String get customCountUnit => '筆';

  @override
  String get customEditTitle => '編輯自訂義';

  @override
  String get customChangePhoto => '更換照片';

  @override
  String get customSummaryLabel => '菜色摘要';

  @override
  String get customSuggestionLabel => '建議';

  @override
  String get customDeleteTitle => '刪除自訂義';

  @override
  String get customDeleteConfirm => '確定刪除這個自訂義？';

  @override
  String get unknownFood => '未命名餐點';

  @override
  String get dietitianPrefix => '建議：';

  @override
  String get dietitianBalanced => '整體均衡，維持即可。';

  @override
  String get dietitianProteinLow => '蛋白質偏低，建議補豆魚蛋肉。';

  @override
  String get dietitianFatHigh => '油脂偏高，下一餐清淡少油。';

  @override
  String get dietitianCarbHigh => '碳水偏多，主食減量。';

  @override
  String get dietitianSodiumHigh => '鈉含量偏高，減少湯底與加工品。';

  @override
  String get multiItemsLabel => '多品項';

  @override
  String get goalAdviceLoseFat => '以減脂為目標，下一餐以蛋白質與蔬菜為主。';

  @override
  String get goalAdviceMaintain => '以維持為主，注意份量與均衡。';

  @override
  String get overallLabel => '整體判斷';

  @override
  String get calorieLabel => '熱量區間';

  @override
  String get editCalorieTitle => '編輯熱量';

  @override
  String get editCalorieHint => '例如 450-600 kcal';

  @override
  String get editCalorieClear => '清除';

  @override
  String get macroLabel => '三大營養';

  @override
  String get levelLow => '低';

  @override
  String get levelMedium => '中';

  @override
  String get levelHigh => '高';

  @override
  String get statusOk => 'OK';

  @override
  String get statusWarn => '偏多';

  @override
  String get statusOver => '爆';

  @override
  String get tagOily => '偏油';

  @override
  String get tagProteinOk => '蛋白質足';

  @override
  String get tagProteinLow => '蛋白質不足';

  @override
  String get tagCarbHigh => '碳水偏多';

  @override
  String get tagOk => 'OK';

  @override
  String get nextMealTitle => '下一餐建議怎麼吃';

  @override
  String get nextMealSectionTitle => '下一餐建議怎麼吃';

  @override
  String get noLateSnackSelfCook => '不建議消夜；若想吃，清湯蔬菜小份';

  @override
  String get noLateSnackConvenience => '不建議消夜；若想吃，無糖豆漿或小份沙拉';

  @override
  String get noLateSnackBento => '不建議消夜；若想吃，半份蔬菜便當';

  @override
  String get noLateSnackOther => '不建議消夜；若想吃，少量水果即可';

  @override
  String get nextMealHint => '選一個最方便的方式就好';

  @override
  String get nextSelfCookLabel => '自煮';

  @override
  String get nextConvenienceLabel => '便利店';

  @override
  String get nextBentoLabel => '便當';

  @override
  String get nextOtherLabel => '其他';

  @override
  String get nextSelfCookHint => '清蒸/水煮＋蔬菜，少油少醬';

  @override
  String get nextConvenienceHint => '茶葉蛋/無糖豆漿/沙拉，少炸物';

  @override
  String get nextBentoHint => '半飯、多菜、優先烤或滷';

  @override
  String get nextOtherHint => '水果/無糖優格/清湯';

  @override
  String get mealItemsTitle => '返回本餐';

  @override
  String get mealTimeSection => '餐次區間';

  @override
  String get breakfastStartLabel => '早餐開始';

  @override
  String get breakfastEndLabel => '早餐結束';

  @override
  String get brunchStartLabel => '早午餐開始';

  @override
  String get brunchEndLabel => '早午餐結束';

  @override
  String get lunchStartLabel => '午餐開始';

  @override
  String get lunchEndLabel => '午餐結束';

  @override
  String get afternoonTeaStartLabel => '下午茶開始';

  @override
  String get afternoonTeaEndLabel => '下午茶結束';

  @override
  String get dinnerStartLabel => '晚餐開始';

  @override
  String get dinnerEndLabel => '晚餐結束';

  @override
  String get lateSnackStartLabel => '消夜開始';

  @override
  String get lateSnackEndLabel => '消夜結束';

  @override
  String get optionConvenienceTitle => '便利商店';

  @override
  String get optionConvenienceDesc => '選茶葉蛋/無糖豆漿/沙拉，少炸物';

  @override
  String get optionBentoTitle => '便當店';

  @override
  String get optionBentoDesc => '半飯、多蔬菜、優先選烤或滷';

  @override
  String get optionLightTitle => '清淡選擇';

  @override
  String get optionLightDesc => '清湯、蒸煮、少醬料';

  @override
  String get summaryTitle => '今日總結';

  @override
  String get summaryEmpty => '今天還沒記錄餐點喔';

  @override
  String get summaryOilyCarb => '今天偏油、碳水也偏多';

  @override
  String get summaryOily => '今天偏油';

  @override
  String get summaryCarb => '今天碳水偏多';

  @override
  String get summaryProteinOk => '蛋白質 OK，記得補點蔬菜';

  @override
  String get summaryNeutral => '今天狀態不錯，繼續保持';

  @override
  String get summaryBeverageOnly => '今天只記錄了飲料';

  @override
  String get includesBeverages => '含飲料';

  @override
  String get proteinIntakeTodayLabel => '今日蛋白質';

  @override
  String proteinIntakeFormat(int consumed, int min, int max) {
    return '已攝取 ${consumed}g / 目標 $min-${max}g';
  }

  @override
  String get smallPortionNote => '份量不多';

  @override
  String get mealsCountLabel => '已記錄';

  @override
  String get mealsLabel => '餐';

  @override
  String get tabCapture => '拍照';

  @override
  String get tabAnalysis => '分析';

  @override
  String get tabNext => '下一餐';

  @override
  String get tabSummary => '摘要';

  @override
  String get tabHome => '首頁';

  @override
  String get tabLog => '紀錄';

  @override
  String get tabSuggest => '即拍建議';

  @override
  String get tabCustom => '自訂義';

  @override
  String get tabSettings => '設定';

  @override
  String greetingTitle(String name) {
    return '嗨 $name，今天也加油';
  }

  @override
  String streakLabel(int count) {
    return '已連續紀錄 $count 天';
  }

  @override
  String get aiSuggest => 'AI 飲食建議';

  @override
  String get latestMealTitle => '剛剛吃的餐點';

  @override
  String get latestMealEmpty => '今天還沒記錄餐點喔';

  @override
  String get homeNextMealHint => '點進建議頁，挑一個最順手的方案';

  @override
  String get logTitle => '紀錄';

  @override
  String get logTopMealTitle => '熱量最高一餐';

  @override
  String get logTopMealEmpty => '近 7 天尚未有完整紀錄';

  @override
  String logRecentDaysTag(String date) {
    return '近 7 天 $date';
  }

  @override
  String get logAddMealPrompt => '補記這一餐';

  @override
  String get dailyCalorieRange => '今日熱量攝取';

  @override
  String get dayCardTitle => '每日摘要';

  @override
  String get dayMealsTitle => '返回本日餐次';

  @override
  String get tomorrowAdviceTitle => '明天建議';

  @override
  String get dayCardDateLabel => '日期：';

  @override
  String get dayCardCalorieLabel => '今日熱量攝取';

  @override
  String get dayCardMealsLabel => '分析餐數：';

  @override
  String get dayCardSummaryLabel => '今日總結';

  @override
  String get dayCardTomorrowLabel => '明日建議';

  @override
  String summaryPendingAt(Object time) {
    return '將於 $time 產生總結';
  }

  @override
  String weekSummaryPendingAt(Object day, Object time) {
    return '將於 $day $time 產生總結';
  }

  @override
  String get finalizeDay => '生成今日總結';

  @override
  String get dishSummaryLabel => '本餐摘要';

  @override
  String get mealCountEmpty => '尚未分析餐次';

  @override
  String get calorieUnknown => '目前還沒有估算結果';

  @override
  String get portionLabel => '份量';

  @override
  String get portionFull => '全吃';

  @override
  String get portionHalf => '吃一半';

  @override
  String get portionBite => '只吃幾口';

  @override
  String get detailTitle => '詳細紀錄';

  @override
  String get detailAiLabel => 'AI 判斷說明';

  @override
  String get detailAiEmpty => '尚無分析資料';

  @override
  String get detailWhyLabel => '為什麼這樣判斷';

  @override
  String get suggestTitle => '即拍建議';

  @override
  String get suggestInstantHint => '拍完馬上分析，給你這餐吃法建議';

  @override
  String get suggestInstantStart => '開始拍照';

  @override
  String get suggestInstantRetake => '拍下一張';

  @override
  String get suggestInstantPickGallery => '從相簿選擇';

  @override
  String get suggestInstantNowEat => '建議我吃什麼';

  @override
  String get suggestInstantNameHint => '輸入食物名稱（沒有照片也可以）';

  @override
  String get suggestInstantNameSubmit => '送出';

  @override
  String get nameAnalyzeStart => '正在分析';

  @override
  String get nameAnalyzeEmpty => '請輸入食物名稱';

  @override
  String get suggestInstantStepDetect => '正在辨識餐點';

  @override
  String get suggestInstantStepEstimate => '估算熱量與份量';

  @override
  String get suggestInstantStepAdvice => '產生吃法建議';

  @override
  String get suggestInstantSavePrompt => '要儲存這餐嗎？';

  @override
  String get suggestInstantSave => '儲存';

  @override
  String get suggestInstantSkipSave => '先不儲存';

  @override
  String get suggestInstantAdviceTitle => '這份食物怎麼吃比較好';

  @override
  String get suggestInstantCanEat => '搭配';

  @override
  String get suggestInstantCanDrink => '可以喝';

  @override
  String get suggestInstantAvoid => '不建議';

  @override
  String get suggestInstantAvoidDrink => '不建議喝';

  @override
  String get suggestInstantLimit => '建議份量';

  @override
  String get suggestInstantDrinkLimit => '建議份量';

  @override
  String get suggestInstantDrinkAdviceTitle => '這杯飲料怎麼喝比較好';

  @override
  String get suggestInstantCanEatInline => '可以怎麼吃';

  @override
  String get suggestInstantRiskInline => '可能會有的問題';

  @override
  String get suggestInstantLimitInline => '建議份量';

  @override
  String get suggestInstantEnergyOk => '可接受';

  @override
  String get suggestInstantEnergyHigh => '偏高';

  @override
  String get suggestInstantMissing => '還沒有分析結果';

  @override
  String get suggestInstantNonFood => '這不是食物，請重拍。若現在不打算吃東西，也歡迎之後肚子餓再使用。';

  @override
  String get suggestInstantReestimate => '重新估算';

  @override
  String get suggestInstantRecentHint => '建議已參考最近 7 天與上一餐';

  @override
  String get suggestAutoSaved => '已自動儲存';

  @override
  String get suggestTodayLabel => '今日整體判斷';

  @override
  String get suggestTodayHint => '今天油脂偏高，下一餐清淡一點';

  @override
  String get suggestTodayOilyCarb => '今天偏油、碳水也偏多';

  @override
  String get suggestTodayOily => '今天偏油，下一餐清淡一點';

  @override
  String get suggestTodayCarb => '今天碳水偏多，下一餐少澱粉';

  @override
  String get suggestTodayOk => '今天狀態不錯，保持就好';

  @override
  String get logThisMeal => '記錄這餐';

  @override
  String get settingsTitle => '設定';

  @override
  String get profileName => '小明';

  @override
  String get profileEmail => 'xiaoming123@gmail.com';

  @override
  String get editProfile => '編輯個人資料';

  @override
  String get nicknameLabel => '暱稱';

  @override
  String get planSection => '計畫設定';

  @override
  String get heightLabel => '身高';

  @override
  String get weightLabel => '體重';

  @override
  String get ageLabel => '年齡';

  @override
  String get genderLabel => '性別';

  @override
  String get genderUnspecified => '不指定';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderOther => '其他';

  @override
  String get bmiLabel => 'BMI';

  @override
  String get bmiUnderweight => '偏低';

  @override
  String get bmiNormal => '正常';

  @override
  String get bmiOverweight => '偏高';

  @override
  String get bmiObese => '過高';

  @override
  String get goalLabel => '目標';

  @override
  String get goalLoseFat => '減脂降體脂';

  @override
  String get reminderSection => '提醒設定';

  @override
  String get reminderLunch => '提醒拍攝午餐';

  @override
  String get reminderDinner => '提醒拍攝晚餐';

  @override
  String get subscriptionSection => '訂閱與其他';

  @override
  String get subscriptionPlan => '目前方案';

  @override
  String get planMonthly => '減脂周數 \$199/月';

  @override
  String get languageLabel => '更換語言';

  @override
  String get langZh => '繁體中文';

  @override
  String get langEn => 'English';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get edit => '編輯';

  @override
  String get editDaySummaryTitle => '編輯今日摘要';

  @override
  String get editMealAdviceTitle => '編輯下一餐建議';

  @override
  String get goalMaintain => '維持體重';

  @override
  String get planSpeedLabel => '減脂速度';

  @override
  String get adviceStyleSection => '建議風格';

  @override
  String get toneLabel => '建議語氣';

  @override
  String get personaLabel => '角色視角';

  @override
  String get toneGentle => '溫和';

  @override
  String get toneDirect => '直接';

  @override
  String get toneEncouraging => '激勵';

  @override
  String get toneBullet => '清楚條列';

  @override
  String get toneStrict => '嚴厲';

  @override
  String get personaNutritionist => '營養師';

  @override
  String get personaCoach => '外食教練';

  @override
  String get personaFriend => '朋友';

  @override
  String get personaSystem => '精簡系統';

  @override
  String get summarySettingsSection => '總結設定';

  @override
  String get summaryTimeLabel => '每日總結';

  @override
  String get weeklySummaryDayLabel => '每周總結';

  @override
  String get weekTopMealTitle => '本週熱量最高一餐';

  @override
  String get recentGuidanceTitle => '近期方針（近 7 天）';

  @override
  String get weekSummaryTitle => '本週總結';

  @override
  String get nextWeekAdviceTitle => '下週建議';

  @override
  String get weekdayMon => '週一';

  @override
  String get weekdayTue => '週二';

  @override
  String get weekdayWed => '週三';

  @override
  String get weekdayThu => '週四';

  @override
  String get weekdayFri => '週五';

  @override
  String get weekdaySat => '週六';

  @override
  String get weekdaySun => '週日';

  @override
  String get planSpeedStable => '穩定';

  @override
  String get planSpeedGentle => '保守';

  @override
  String get activityLevelLabel => '預設活動量';

  @override
  String get activityLabel => '活動量';

  @override
  String get activityCardTitle => '今日活動量';

  @override
  String get targetCalorieUnknown => '尚未估計';

  @override
  String get activitySedentary => '久坐';

  @override
  String get activityLight => '輕量';

  @override
  String get activityModerate => '中度';

  @override
  String get activityHigh => '高';

  @override
  String get exerciseNoExercise => '無運動';

  @override
  String get exerciseLabel => '運動';

  @override
  String get exerciseMinutesLabel => '時間';

  @override
  String get exerciseMinutesUnit => '分鐘';

  @override
  String get exerciseMinutesHint => '輸入分鐘數';

  @override
  String get exerciseCaloriesLabel => '運動消耗';

  @override
  String get exerciseNone => '無運動';

  @override
  String get exerciseWalking => '快走';

  @override
  String get exerciseJogging => '慢跑';

  @override
  String get exerciseCycling => '單車';

  @override
  String get exerciseSwimming => '游泳';

  @override
  String get exerciseStrength => '重量訓練';

  @override
  String get exerciseYoga => '瑜伽';

  @override
  String get exerciseHiit => '間歇訓練';

  @override
  String get exerciseBasketball => '籃球';

  @override
  String get exerciseHiking => '登山';

  @override
  String get deltaUnknown => '尚未估計';

  @override
  String get deltaOk => '接近目標';

  @override
  String deltaSurplus(int kcal) {
    return '超出 $kcal kcal';
  }

  @override
  String deltaDeficit(int kcal) {
    return '赤字 $kcal kcal';
  }

  @override
  String get commonExerciseLabel => '常用運動';

  @override
  String get suggestRemainingTitle => '今天還能吃多少';

  @override
  String suggestRemainingLeft(int cal) {
    return '還可以吃 $cal kcal';
  }

  @override
  String suggestRemainingOver(int cal) {
    return '已超過 $cal kcal';
  }

  @override
  String suggestExerciseHint(String exercise, int minutes) {
    return '建議做 $exercise 約 $minutes 分鐘';
  }

  @override
  String get reminderLunchTime => '午餐提醒時間';

  @override
  String get reminderDinnerTime => '晚餐提醒時間';

  @override
  String get pickFromCamera => '拍照';

  @override
  String get pickFromGallery => '從相簿選擇';

  @override
  String get addMeal => '新增';

  @override
  String get noMealPrompt => '尚未紀錄，拍一張也可以';

  @override
  String get layoutThemeLabel => '主題與版面';

  @override
  String get textSizeLabel => '字體大小';

  @override
  String get textSizeSmall => '標準';

  @override
  String get textSizeMedium => '偏大';

  @override
  String get textSizeLarge => '特大';

  @override
  String get themeClean => '清爽藍';

  @override
  String get glowToggleLabel => '柔光背景';

  @override
  String get themeGreen => '清爽綠';

  @override
  String get themeWarm => '暖橘';

  @override
  String get themePink => '柔粉';

  @override
  String get plateSection => '盤子樣式';

  @override
  String get plateStyleLabel => '盤子款式';

  @override
  String get plateDefaultLabel => '預設瓷盤';

  @override
  String get plateWarmLabel => '暖色陶瓷盤';

  @override
  String get apiSection => 'API 連線';

  @override
  String get apiBaseUrlLabel => 'API 位址';

  @override
  String get delete => '刪除';

  @override
  String get deleteConfirm => '確定要刪除此紀錄嗎？';

  @override
  String get logSuccess => '已記錄這餐';

  @override
  String get viewLog => '查看紀錄';

  @override
  String get calories => '熱量';

  @override
  String get estimated => 'AI 估算';

  @override
  String get protein => '蛋白質';

  @override
  String get carbs => '碳水';

  @override
  String get fat => '脂肪';

  @override
  String get sodium => '鈉含量';

  @override
  String get tier => '層級';

  @override
  String get analyzeFailed => '目前無法分析';

  @override
  String get costEstimateLabel => '估算花費';

  @override
  String get usageSection => 'AI 花費';

  @override
  String get usageTotalLabel => '累計花費';

  @override
  String get usageViewLog => '查看紀錄';

  @override
  String get usageEmpty => '尚無花費紀錄';

  @override
  String get usageLoading => '載入中...';

  @override
  String get mockPrefix => '預覽';

  @override
  String get versionSection => '版本資訊';

  @override
  String get versionBuild => '更新時間';

  @override
  String get versionCommit => '版本代碼';

  @override
  String get versionUnavailable => '無法取得版本資訊';

  @override
  String get nutritionChartLabel => '營養圖表';

  @override
  String get nutritionValueLabel => '營養顯示';

  @override
  String get nutritionValuePercent => '百分比';

  @override
  String get nutritionValueAmount => '數值';

  @override
  String get chartRadar => '雷達圖';

  @override
  String get chartBars => '條狀圖';

  @override
  String get chartDonut => '圓環圖';

  @override
  String get dataSection => '資料管理';

  @override
  String get syncSection => '帳號與同步';

  @override
  String get syncSignedInAs => '已登入：';

  @override
  String get syncNotSignedIn => '尚未登入';

  @override
  String get syncEmailLabel => 'Email';

  @override
  String get syncPasswordLabel => '密碼';

  @override
  String get syncSignIn => '登入';

  @override
  String get syncSignUp => '註冊';

  @override
  String get syncSignUpSuccess => '已寄送驗證信，請先完成信箱驗證';

  @override
  String get syncSignInSuccess => '登入成功';

  @override
  String get syncForgotPassword => '忘記密碼';

  @override
  String get syncResetPasswordTitle => '重設密碼';

  @override
  String get syncResetPasswordHint => '輸入註冊信箱';

  @override
  String get syncResetPasswordSent => '已寄送重設密碼郵件';

  @override
  String get syncSignOut => '登出';

  @override
  String get syncUpload => '上傳同步';

  @override
  String get syncDownload => '下載同步';

  @override
  String get syncNow => '同步';

  @override
  String get syncInProgress => '正在努力同步中…';

  @override
  String get syncSuccess => '同步完成囉';

  @override
  String get syncUpdated => '更新完成';

  @override
  String get syncNoChanges => '目前沒有要同步的資料';

  @override
  String get syncError => '同步失敗，請稍後再試';

  @override
  String get syncRequireLogin => '先登入才能同步喔';

  @override
  String get syncAuthTitleSignIn => '登入帳號';

  @override
  String get syncAuthTitleSignUp => '註冊帳號';

  @override
  String get exportData => '匯出資料';

  @override
  String get clearData => '清除資料';

  @override
  String get clearDataConfirm => '確定要清除所有資料嗎？';

  @override
  String get exportDone => '已匯出';

  @override
  String get clearDone => '已清除';

  @override
  String get close => '關閉';

  @override
  String get authTitle => '歡迎使用 Food AI';

  @override
  String get authSubtitle => '登入後即可使用完整功能';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => '請輸入 Email';

  @override
  String get authEmailInvalid => 'Email 格式不正確';

  @override
  String get authPasswordLabel => '密碼';

  @override
  String get authConfirmPasswordLabel => '確認密碼';

  @override
  String get authSignIn => '登入';

  @override
  String get authSignUp => '註冊';

  @override
  String get authToggleToSignUp => '沒有帳號？立即註冊';

  @override
  String get authToggleToSignIn => '已有帳號？返回登入';

  @override
  String get authForgotPassword => '忘記密碼';

  @override
  String get authSignInSuccess => '登入成功';

  @override
  String get authSignUpSuccess => '註冊完成';

  @override
  String get authSignUpVerify => '註冊完成，請前往信箱完成驗證';

  @override
  String get authEmailNotVerified => '此 Email 尚未驗證，請先完成信箱驗證';

  @override
  String get authVerifyTitle => '請驗證信箱';

  @override
  String authVerifyBody(String email) {
    return '我們已寄送驗證信到 $email，請在 1-3 分鐘內查看，也請檢查垃圾郵件/促銷匣。';
  }

  @override
  String get authResend => '重新寄送驗證信';

  @override
  String authResendCooldown(int seconds) {
    return '重新寄送（${seconds}s）';
  }

  @override
  String get authResendSent => '驗證信已重新寄出';

  @override
  String get authResendFailed => '重新寄送失敗，請稍後再試';

  @override
  String get authTooManyAttempts => '請稍後再試';

  @override
  String get authPasswordMismatch => '兩次密碼不一致';

  @override
  String get authPasswordRule => '密碼至少 8 碼，且不可含空白或中文';

  @override
  String get authPasswordInvalid => '密碼需至少 8 碼，且不可含空白或中文';

  @override
  String get authResetSent => '重設密碼信已寄出，請查看信箱';

  @override
  String get authResetFailed => '重設失敗，請確認 Email 是否正確';

  @override
  String get authLoginInvalid => 'Email 或密碼錯誤';

  @override
  String get authEmailExists => '此 Email 已註冊';

  @override
  String get authNetworkError => '連線異常，請稍後再試';

  @override
  String get authSignUpFailed => '註冊失敗';

  @override
  String get authError => '登入失敗，請稍後再試';

  @override
  String get trialExpiredTitle => '試用期已結束';

  @override
  String get trialExpiredBody => '你已完成 2 天免費試用，請訂閱後繼續使用 AI 分析功能。';

  @override
  String get trialExpiredAction => '了解方案';

  @override
  String get signOut => '登出';

  @override
  String get dietPreferenceSection => '飲食偏好';

  @override
  String get dietTypeLabel => '飲食類型';

  @override
  String get dietNoteLabel => '偏好補充';

  @override
  String get dietTypeNone => '不限制';

  @override
  String get dietTypeVegetarian => '奶蛋素';

  @override
  String get dietTypeVegan => '全素';

  @override
  String get dietTypePescatarian => '海鮮素';

  @override
  String get dietTypeLowCarb => '低碳';

  @override
  String get dietTypeKeto => '生酮';

  @override
  String get dietTypeLowFat => '低脂';

  @override
  String get dietTypeHighProtein => '高蛋白';

  @override
  String get authNicknameRequired => '請輸入暱稱';

  @override
  String get containerSection => '常用容器';

  @override
  String get containerTypeLabel => '容器類型';

  @override
  String get containerSizeLabel => '容器尺寸';

  @override
  String get containerDepthLabel => '碗深度';

  @override
  String get containerDiameterLabel => '直徑 (cm)';

  @override
  String get containerCapacityLabel => '容量 (ml)';

  @override
  String get containerTypeBowl => '碗';

  @override
  String get containerTypePlate => '盤';

  @override
  String get containerTypeBox => '便當盒';

  @override
  String get containerTypeCup => '杯';

  @override
  String get containerTypeUnknown => '不指定';

  @override
  String get containerSizeSmall => '小';

  @override
  String get containerSizeMedium => '中';

  @override
  String get containerSizeLarge => '大';

  @override
  String get containerSizeStandard => '標準';

  @override
  String get containerSizeCustom => '自訂';

  @override
  String get containerDepthShallow => '淺';

  @override
  String get containerDepthMedium => '中';

  @override
  String get containerDepthDeep => '深';
}
