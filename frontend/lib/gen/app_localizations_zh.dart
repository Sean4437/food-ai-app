// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MiraMeal';

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
  String get noLateSnackSelfCook => '如果今晚還想吃，先選清湯蔬菜小份';

  @override
  String get noLateSnackConvenience => '如果今晚還想吃，先選無糖豆漿或小份沙拉';

  @override
  String get noLateSnackBento => '如果今晚還想吃，先選半份蔬菜便當';

  @override
  String get noLateSnackOther => '如果今晚還想吃，先少量水果就好';

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
  String get summaryTitle => '今天的重点';

  @override
  String get summaryEmpty => '今天还没有餐点记录';

  @override
  String get summaryOilyCarb => '今天油脂和淀粉都偏多';

  @override
  String get summaryOily => '今天油脂稍微偏多';

  @override
  String get summaryCarb => '今天淀粉稍微偏多';

  @override
  String get summaryProteinOk => '今天蛋白质有跟上，记得补点蔬菜';

  @override
  String get summaryNeutral => '今天整体稳稳的，照这个节奏就好';

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
    return '嗨 $name，来看看今天吃得怎么样';
  }

  @override
  String streakLabel(int count) {
    return '连续记录 $count 天';
  }

  @override
  String get aiSuggest => 'MiraMeal 小提醒';

  @override
  String get latestMealTitle => '今天最近一餐';

  @override
  String get latestMealEmpty => '今天还没有餐点记录';

  @override
  String get homeNextMealHint => '想知道下一餐怎么接，点进建议页就好';

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
  String get dayCardTitle => '今天的状态';

  @override
  String get dayMealsTitle => '返回本日餐次';

  @override
  String get tomorrowAdviceTitle => '接下来怎么吃';

  @override
  String get dayCardDateLabel => '日期：';

  @override
  String get dayCardCalorieLabel => '能量狀態';

  @override
  String get dayCardProteinLabel => '蛋白質狀態';

  @override
  String get calorieHistoryTitle => '熱量趨勢';

  @override
  String calorieTrendTargetLabel(Object max, Object min) {
    return '目標 $min-$max';
  }

  @override
  String get calorieTrendSummaryWeekTitle => '本週總結';

  @override
  String get calorieTrendSummaryTwoWeeksTitle => '兩週總結';

  @override
  String get calorieTrendSummaryMonthTitle => '本月總結';

  @override
  String get calorieTrendCompareLastWeek => '上週';

  @override
  String get calorieTrendCompareLastTwoWeeks => '前兩週';

  @override
  String get calorieTrendCompareLastMonth => '上月';

  @override
  String get calorieTrendSummaryNoData => '尚無資料';

  @override
  String calorieTrendSummaryNoPrev(Object avg) {
    return '平均攝取 $avg kcal，尚無前期資料。';
  }

  @override
  String calorieTrendSummaryHigher(Object avg, Object pct, Object period) {
    return '平均攝取 $avg kcal，高於$period $pct%。';
  }

  @override
  String calorieTrendSummaryLower(Object avg, Object pct, Object period) {
    return '平均攝取 $avg kcal，低於$period $pct%。';
  }

  @override
  String calorieTrendSummarySame(Object avg, Object period) {
    return '平均攝取 $avg kcal，與$period持平。';
  }

  @override
  String get proteinTrendTitle => '蛋白質趨勢';

  @override
  String proteinTrendTargetLabel(Object value) {
    return '目標 $value g';
  }

  @override
  String get proteinTrendSummaryNoData => '尚無資料';

  @override
  String proteinTrendSummaryNoPrev(Object avg) {
    return '平均攝取 $avg g，尚無前期資料。';
  }

  @override
  String proteinTrendSummaryHigher(Object avg, Object pct, Object period) {
    return '平均攝取 $avg g，高於$period $pct%。';
  }

  @override
  String proteinTrendSummaryLower(Object avg, Object pct, Object period) {
    return '平均攝取 $avg g，低於$period $pct%。';
  }

  @override
  String proteinTrendSummarySame(Object avg, Object period) {
    return '平均攝取 $avg g，與$period持平。';
  }

  @override
  String get dayCardMealsLabel => '分析餐數：';

  @override
  String get dayCardSummaryLabel => '今天重点';

  @override
  String get dayCardTomorrowLabel => '接下来建议';

  @override
  String summaryPendingAt(Object time) {
    return '今天重点会在 $time 准备好';
  }

  @override
  String weekSummaryPendingAt(Object day, Object time) {
    return '这周回顾会在 $day $time 准备好';
  }

  @override
  String get finalizeDay => '整理今天重点';

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
  String get suggestInstantCanEat => '一起搭';

  @override
  String get suggestInstantCanDrink => '可以喝';

  @override
  String get suggestInstantAvoid => '先少一点';

  @override
  String get suggestInstantAvoidDrink => '先少喝一点';

  @override
  String get suggestInstantLimit => '这样吃刚好';

  @override
  String get suggestInstantDrinkLimit => '这样喝刚好';

  @override
  String get suggestInstantDrinkAdviceTitle => '这杯饮料怎么喝比较好';

  @override
  String get suggestInstantCanEatInline => '可以怎么搭';

  @override
  String get suggestInstantRiskInline => '先留意';

  @override
  String get suggestInstantLimitInline => '刚好的份量';

  @override
  String get suggestInstantEnergyOk => '可接受';

  @override
  String get suggestInstantEnergyHigh => '偏高';

  @override
  String get suggestInstantMissing => '還沒有分析結果';

  @override
  String get suggestInstantNonFood => '这张好像不是食物耶～要不要再拍一次？如果现在不打算吃也没关系，等肚子饿再来～';

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
  String get reminderTimeNote => '提醒時間會跟餐次開始時間同步';

  @override
  String get reminderBreakfast => '提醒拍攝早餐';

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
  String get summarySettingsSection => '自动整理';

  @override
  String get summaryTimeLabel => '每日总览';

  @override
  String get weeklySummaryDayLabel => '每周回顾';

  @override
  String get weekTopMealTitle => '本週熱量最高一餐';

  @override
  String get recentGuidanceTitle => '最近 7 天提醒';

  @override
  String get weekSummaryTitle => '这周回顾';

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
  String proteinRemainingLeft(int grams) {
    return '還可以吃 $grams g';
  }

  @override
  String proteinRemainingOver(int grams) {
    return '已超過 $grams g';
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
  String get reminderBreakfastTime => '早餐提醒時間';

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
  String get apiBaseUrlReset => '清除舊 API 並重設';

  @override
  String get apiBaseUrlResetDone => '已重設 API 位址';

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
  String get reestimateFailedKeepLast => '重新估算失敗，已保留上一版結果';

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
  String get syncSwitchAccount => '切換帳號';

  @override
  String get syncSwitchAccountConfirmTitle => '切換帳號';

  @override
  String get syncSwitchAccountConfirmMessage => '將清除本機資料並登出，確定要切換帳號嗎？';

  @override
  String get syncSwitchAccountConfirmAction => '切換';

  @override
  String get syncSwitchAccountDone => '已切換帳號，資料已清空。';

  @override
  String get syncUpload => '上傳同步';

  @override
  String get syncDownload => '下載同步';

  @override
  String get syncNow => '同步';

  @override
  String get syncInProgress => '正在努力同步中…';

  @override
  String get syncLastSyncLabel => '上次同步：';

  @override
  String get syncLastResultLabel => '上次結果：';

  @override
  String get syncLastResultNone => '尚無紀錄';

  @override
  String get syncLastResultNoChanges => '無變更';

  @override
  String get syncFailedItemsLabel => '失敗項目：';

  @override
  String syncFailedItemsCount(int count) {
    return '$count 項';
  }

  @override
  String get syncRetryFailed => '重試失敗項';

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
  String get authTitle => '歡迎使用 MiraMeal';

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
  String get authNicknameInvalid => '昵称需 2-24 个字';

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

  @override
  String get paywallTitle => '解鎖完整功能';

  @override
  String get paywallSubtitle => 'AI 分析、營養圖、週／月總結';

  @override
  String planMonthlyWithPrice(String price) {
    return '月訂 $price';
  }

  @override
  String planYearlyWithPrice(String price) {
    return '年訂 $price';
  }

  @override
  String get paywallYearlyBadge => '年訂省下約 30%';

  @override
  String get paywallRestore => '恢復購買';

  @override
  String get paywallDisclaimer => '訂閱將自動續訂，可隨時在 Apple ID 訂閱管理中取消。付款由 Apple 處理。';

  @override
  String get paywallStartMonthly => '開始月訂';

  @override
  String get paywallStartYearly => '開始年訂';

  @override
  String get paywallFeatureAiAnalysis => '完整 AI 分析';

  @override
  String get paywallFeatureNutritionAdvice => '熱量與營養建議';

  @override
  String get paywallFeatureSummaries => '週／月總結';

  @override
  String get paywallFeatureBestValue => '更划算的長期方案';

  @override
  String get paywallUnavailableTitle => '無法載入訂閱';

  @override
  String get paywallUnavailableBody => '目前無法取得 App Store 訂閱資訊，請稍後再試。';

  @override
  String get webPaywallTitle => '解鎖完整功能（Web 測試）';

  @override
  String get webPaywallTestBadge => '僅供測試，不會扣款';

  @override
  String get webPaywallCurrentPlanMonthly => '目前方案：月訂（測試）';

  @override
  String get webPaywallCurrentPlanYearly => '目前方案：年訂（測試）';

  @override
  String get webPaywallCurrentPlanNone => '目前方案：未訂閱';

  @override
  String get webPaywallTestNote => 'Web 測試版：此流程不會實際扣款。';

  @override
  String get webPaywallActivated => '已啟用測試訂閱';

  @override
  String get webPaywallSuccessTitle => '測試訂閱成功';

  @override
  String get webPaywallSuccessBody => '已解鎖完整功能（測試模式）。';

  @override
  String get webPaywallSuccessCta => '開始使用';

  @override
  String get dialogOk => '知道了';

  @override
  String get syncErrorUploadFailedDetail => '圖片上傳失敗';

  @override
  String get syncErrorSyncMetaFailedDetail => '同步狀態寫入失敗';

  @override
  String get syncErrorPostgrestDetail => '資料庫存取失敗';

  @override
  String get syncErrorNetworkDetail => '網路連線失敗';

  @override
  String syncSummaryUploadMeals(int count) {
    return '上傳餐點 $count';
  }

  @override
  String syncSummaryDeleteMeals(int count) {
    return '刪除餐點 $count';
  }

  @override
  String syncSummaryUploadCustom(int count) {
    return '上傳自訂食物 $count';
  }

  @override
  String syncSummaryDeleteCustom(int count) {
    return '刪除自訂食物 $count';
  }

  @override
  String syncSummaryUploadSettings(int count) {
    return '上傳設定 $count';
  }

  @override
  String syncSummaryDownloadMeals(int count) {
    return '下載餐點 $count';
  }

  @override
  String syncSummaryDownloadDeletedMeals(int count) {
    return '下載刪除餐點 $count';
  }

  @override
  String syncSummaryDownloadCustom(int count) {
    return '下載自訂食物 $count';
  }

  @override
  String syncSummaryDownloadDeletedCustom(int count) {
    return '下載刪除自訂食物 $count';
  }

  @override
  String syncSummaryDownloadSettings(int count) {
    return '下載設定 $count';
  }

  @override
  String get syncSummarySeparator => '、';

  @override
  String get plateJapanese02 => '日式盤 02';

  @override
  String get plateJapanese04 => '日式盤 04';

  @override
  String get plateChina01 => '中式盤 01';

  @override
  String get plateChina02 => '中式盤 02';

  @override
  String get placeholderDash => '--';

  @override
  String valueWithCm(int value) {
    return '$value 公分';
  }

  @override
  String valueWithKg(int value) {
    return '$value 公斤';
  }

  @override
  String valueWithMl(int value) {
    return '$value 毫升';
  }

  @override
  String get referenceObjectLabel => '參考物';

  @override
  String get referenceObjectNone => '無';

  @override
  String get referenceObjectCard => '信用卡';

  @override
  String get referenceObjectCoin10 => '10 元硬幣';

  @override
  String get referenceObjectCoin5 => '5 元硬幣';

  @override
  String get referenceObjectManual => '測距（公分）';

  @override
  String get referenceLengthLabel => '測距長度（公分）';

  @override
  String get referenceLengthHint => '輸入 iOS 測距量到的公分';

  @override
  String get referenceLengthApply => '套用';

  @override
  String get tabChat => '聊天';

  @override
  String get tabChatAssistant => '咚咚';

  @override
  String get chatSettingsSection => '聊天设置';

  @override
  String get chatAssistantDefaultName => '咚咚';

  @override
  String get chatEmptyHint => '嗨，我是咚咚。你可以问我今天吃得怎么样，或下一餐怎么安排。';

  @override
  String chatEmptyHintWithName(Object name) {
    return '嗨，我是$name。你可以问我今天吃得怎么样，或下一餐怎么安排。';
  }

  @override
  String get chatInputHint => '问我今天怎么吃...';

  @override
  String get chatLockedTitle => '订阅后可开启聊天陪伴';

  @override
  String get chatLockedBody => '开启后可以直接问今天吃得如何、下一餐怎么接，或请我帮你整理重点。';

  @override
  String get chatLockedAction => '查看订阅';

  @override
  String get chatClearTitle => '清除聊天记录？';

  @override
  String get chatClearBody => '这会移除这台装置上的对话内容。';

  @override
  String get chatClearConfirm => '清除';

  @override
  String get chatError => '聊天失败，请稍后再试';

  @override
  String get chatErrorAuth => '登入已过期，请重新登入';

  @override
  String get chatErrorQuota => '今日聊天额度已用完，请稍后再试';

  @override
  String get chatErrorServer => '我这边刚刚有点忙，稍后再试';

  @override
  String get chatErrorNetwork => '网路不稳定，请稍后再试';

  @override
  String get chatErrorReplyBase => '我刚刚没整理好这次回答，稍后再问我一次好吗？';

  @override
  String get chatErrorReasonPrefix => '原因：';

  @override
  String get chatErrorReasonAuth => '登入已过期或权限不足';

  @override
  String get chatErrorReasonQuota => '请求太频繁或额度已用完';

  @override
  String get chatErrorReasonServer => '服务器忙碌或暂时出错';

  @override
  String get chatErrorReasonNetwork => '网路不稳定或连线中断';

  @override
  String get chatErrorReasonUnknown => '暂时无法判断';

  @override
  String get chatAvatarLabel => '聊天头像';

  @override
  String get chatAssistantNameLabel => '助手名称';

  @override
  String get chatAvatarSet => '已设置';

  @override
  String get chatAvatarUnset => '未设置';

  @override
  String get chatAvatarSheetTitle => '设置聊天头像';

  @override
  String get chatAvatarPick => '选择照片';

  @override
  String get chatAvatarRemove => '移除照片';

  @override
  String get authResetPasswordTitle => '重設密碼';

  @override
  String get authNewPasswordLabel => '新密碼';

  @override
  String get authPasswordRequired => '請輸入密碼';

  @override
  String get authPasswordUpdated => '密碼已更新';

  @override
  String get authResetPasswordAction => '更新密碼';

  @override
  String get authResetLinkInvalid => '連結已失效，請重新寄送重設密碼信';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'MiraMeal';

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
  String get noLateSnackSelfCook => '如果今晚還想吃，先選清湯蔬菜小份';

  @override
  String get noLateSnackConvenience => '如果今晚還想吃，先選無糖豆漿或小份沙拉';

  @override
  String get noLateSnackBento => '如果今晚還想吃，先選半份蔬菜便當';

  @override
  String get noLateSnackOther => '如果今晚還想吃，先少量水果就好';

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
  String get summaryTitle => '今天的重點';

  @override
  String get summaryEmpty => '今天還沒有餐點紀錄';

  @override
  String get summaryOilyCarb => '今天油脂和澱粉都偏多';

  @override
  String get summaryOily => '今天油脂稍微偏多';

  @override
  String get summaryCarb => '今天澱粉稍微偏多';

  @override
  String get summaryProteinOk => '今天蛋白質有跟上，記得補點蔬菜';

  @override
  String get summaryNeutral => '今天整體穩穩的，照這個節奏就好';

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
    return '嗨 $name，來看看今天吃得怎麼樣';
  }

  @override
  String streakLabel(int count) {
    return '連續記錄 $count 天';
  }

  @override
  String get aiSuggest => 'MiraMeal 小提醒';

  @override
  String get latestMealTitle => '今天最近一餐';

  @override
  String get latestMealEmpty => '今天還沒有餐點紀錄';

  @override
  String get homeNextMealHint => '想知道下一餐怎麼接，點進建議頁就好';

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
  String get dayCardTitle => '今天的狀態';

  @override
  String get dayMealsTitle => '返回本日餐次';

  @override
  String get tomorrowAdviceTitle => '接下來怎麼吃';

  @override
  String get dayCardDateLabel => '日期：';

  @override
  String get dayCardCalorieLabel => '能量狀態';

  @override
  String get dayCardProteinLabel => '蛋白質狀態';

  @override
  String get calorieHistoryTitle => '熱量趨勢';

  @override
  String calorieTrendTargetLabel(Object max, Object min) {
    return '目標 $min-$max';
  }

  @override
  String get calorieTrendSummaryWeekTitle => '本週總結';

  @override
  String get calorieTrendSummaryTwoWeeksTitle => '兩週總結';

  @override
  String get calorieTrendSummaryMonthTitle => '本月總結';

  @override
  String get calorieTrendCompareLastWeek => '上週';

  @override
  String get calorieTrendCompareLastTwoWeeks => '前兩週';

  @override
  String get calorieTrendCompareLastMonth => '上月';

  @override
  String get calorieTrendSummaryNoData => '尚無資料';

  @override
  String calorieTrendSummaryNoPrev(Object avg) {
    return '平均攝取 $avg kcal，尚無前期資料。';
  }

  @override
  String calorieTrendSummaryHigher(Object avg, Object pct, Object period) {
    return '平均攝取 $avg kcal，高於$period $pct%。';
  }

  @override
  String calorieTrendSummaryLower(Object avg, Object pct, Object period) {
    return '平均攝取 $avg kcal，低於$period $pct%。';
  }

  @override
  String calorieTrendSummarySame(Object avg, Object period) {
    return '平均攝取 $avg kcal，與$period持平。';
  }

  @override
  String get proteinTrendTitle => '蛋白質趨勢';

  @override
  String proteinTrendTargetLabel(Object value) {
    return '目標 $value g';
  }

  @override
  String get proteinTrendSummaryNoData => '尚無資料';

  @override
  String proteinTrendSummaryNoPrev(Object avg) {
    return '平均攝取 $avg g，尚無前期資料。';
  }

  @override
  String proteinTrendSummaryHigher(Object avg, Object pct, Object period) {
    return '平均攝取 $avg g，高於$period $pct%。';
  }

  @override
  String proteinTrendSummaryLower(Object avg, Object pct, Object period) {
    return '平均攝取 $avg g，低於$period $pct%。';
  }

  @override
  String proteinTrendSummarySame(Object avg, Object period) {
    return '平均攝取 $avg g，與$period持平。';
  }

  @override
  String get dayCardMealsLabel => '分析餐數：';

  @override
  String get dayCardSummaryLabel => '今天重點';

  @override
  String get dayCardTomorrowLabel => '接下來建議';

  @override
  String summaryPendingAt(Object time) {
    return '今天重點會在 $time 準備好';
  }

  @override
  String weekSummaryPendingAt(Object day, Object time) {
    return '這週回顧會在 $day $time 準備好';
  }

  @override
  String get finalizeDay => '整理今天重點';

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
  String get suggestInstantCanEat => '一起搭';

  @override
  String get suggestInstantCanDrink => '可以喝';

  @override
  String get suggestInstantAvoid => '先少一點';

  @override
  String get suggestInstantAvoidDrink => '先少喝一點';

  @override
  String get suggestInstantLimit => '這樣吃剛好';

  @override
  String get suggestInstantDrinkLimit => '這樣喝剛好';

  @override
  String get suggestInstantDrinkAdviceTitle => '這杯飲料怎麼喝比較好';

  @override
  String get suggestInstantCanEatInline => '可以怎麼搭';

  @override
  String get suggestInstantRiskInline => '先留意';

  @override
  String get suggestInstantLimitInline => '剛好的份量';

  @override
  String get suggestInstantEnergyOk => '可接受';

  @override
  String get suggestInstantEnergyHigh => '偏高';

  @override
  String get suggestInstantMissing => '還沒有分析結果';

  @override
  String get suggestInstantNonFood => '這張好像不是食物耶～要不要再拍一次？如果現在不打算吃也沒關係，等肚子餓再來～';

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
  String get reminderTimeNote => '提醒時間會跟餐次開始時間同步';

  @override
  String get reminderBreakfast => '提醒拍攝早餐';

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
  String get summarySettingsSection => '自動整理';

  @override
  String get summaryTimeLabel => '每日總結';

  @override
  String get weeklySummaryDayLabel => '每週回顧';

  @override
  String get weekTopMealTitle => '本週熱量最高一餐';

  @override
  String get recentGuidanceTitle => '最近 7 天提醒';

  @override
  String get weekSummaryTitle => '這週回顧';

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
  String proteinRemainingLeft(int grams) {
    return '還可以吃 $grams g';
  }

  @override
  String proteinRemainingOver(int grams) {
    return '已超過 $grams g';
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
  String get reminderBreakfastTime => '早餐提醒時間';

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
  String get apiBaseUrlReset => '清除舊 API 並重設';

  @override
  String get apiBaseUrlResetDone => '已重設 API 位址';

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
  String get reestimateFailedKeepLast => '重新估算失敗，已保留上一版結果';

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
  String get syncSwitchAccount => '切換帳號';

  @override
  String get syncSwitchAccountConfirmTitle => '切換帳號';

  @override
  String get syncSwitchAccountConfirmMessage => '將清除本機資料並登出，確定要切換帳號嗎？';

  @override
  String get syncSwitchAccountConfirmAction => '切換';

  @override
  String get syncSwitchAccountDone => '已切換帳號，資料已清空。';

  @override
  String get syncUpload => '上傳同步';

  @override
  String get syncDownload => '下載同步';

  @override
  String get syncNow => '同步';

  @override
  String get syncInProgress => '正在努力同步中…';

  @override
  String get syncLastSyncLabel => '上次同步：';

  @override
  String get syncLastResultLabel => '上次結果：';

  @override
  String get syncLastResultNone => '尚無紀錄';

  @override
  String get syncLastResultNoChanges => '無變更';

  @override
  String get syncFailedItemsLabel => '失敗項目：';

  @override
  String syncFailedItemsCount(int count) {
    return '$count 項';
  }

  @override
  String get syncRetryFailed => '重試失敗項';

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
  String get authTitle => '歡迎使用 MiraMeal';

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
  String get authNicknameInvalid => '暱稱需 2-24 個字';

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

  @override
  String get paywallTitle => '解鎖完整功能';

  @override
  String get paywallSubtitle => 'AI 分析、營養圖、週／月總結';

  @override
  String planMonthlyWithPrice(String price) {
    return '月訂 $price';
  }

  @override
  String planYearlyWithPrice(String price) {
    return '年訂 $price';
  }

  @override
  String get paywallYearlyBadge => '年訂省下約 30%';

  @override
  String get paywallRestore => '恢復購買';

  @override
  String get paywallDisclaimer => '訂閱將自動續訂，可隨時在 Apple ID 訂閱管理中取消。付款由 Apple 處理。';

  @override
  String get paywallStartMonthly => '開始月訂';

  @override
  String get paywallStartYearly => '開始年訂';

  @override
  String get paywallFeatureAiAnalysis => '完整 AI 分析';

  @override
  String get paywallFeatureNutritionAdvice => '熱量與營養建議';

  @override
  String get paywallFeatureSummaries => '週／月總結';

  @override
  String get paywallFeatureBestValue => '更划算的長期方案';

  @override
  String get paywallUnavailableTitle => '無法載入訂閱';

  @override
  String get paywallUnavailableBody => '目前無法取得 App Store 訂閱資訊，請稍後再試。';

  @override
  String get webPaywallTitle => '解鎖完整功能（Web 測試）';

  @override
  String get webPaywallTestBadge => '僅供測試，不會扣款';

  @override
  String get webPaywallCurrentPlanMonthly => '目前方案：月訂（測試）';

  @override
  String get webPaywallCurrentPlanYearly => '目前方案：年訂（測試）';

  @override
  String get webPaywallCurrentPlanNone => '目前方案：未訂閱';

  @override
  String get webPaywallTestNote => 'Web 測試版：此流程不會實際扣款。';

  @override
  String get webPaywallActivated => '已啟用測試訂閱';

  @override
  String get webPaywallSuccessTitle => '測試訂閱成功';

  @override
  String get webPaywallSuccessBody => '已解鎖完整功能（測試模式）。';

  @override
  String get webPaywallSuccessCta => '開始使用';

  @override
  String get dialogOk => '知道了';

  @override
  String get syncErrorUploadFailedDetail => '圖片上傳失敗';

  @override
  String get syncErrorSyncMetaFailedDetail => '同步狀態寫入失敗';

  @override
  String get syncErrorPostgrestDetail => '資料庫存取失敗';

  @override
  String get syncErrorNetworkDetail => '網路連線失敗';

  @override
  String syncSummaryUploadMeals(int count) {
    return '上傳餐點 $count';
  }

  @override
  String syncSummaryDeleteMeals(int count) {
    return '刪除餐點 $count';
  }

  @override
  String syncSummaryUploadCustom(int count) {
    return '上傳自訂食物 $count';
  }

  @override
  String syncSummaryDeleteCustom(int count) {
    return '刪除自訂食物 $count';
  }

  @override
  String syncSummaryUploadSettings(int count) {
    return '上傳設定 $count';
  }

  @override
  String syncSummaryDownloadMeals(int count) {
    return '下載餐點 $count';
  }

  @override
  String syncSummaryDownloadDeletedMeals(int count) {
    return '下載刪除餐點 $count';
  }

  @override
  String syncSummaryDownloadCustom(int count) {
    return '下載自訂食物 $count';
  }

  @override
  String syncSummaryDownloadDeletedCustom(int count) {
    return '下載刪除自訂食物 $count';
  }

  @override
  String syncSummaryDownloadSettings(int count) {
    return '下載設定 $count';
  }

  @override
  String get syncSummarySeparator => '、';

  @override
  String get plateJapanese02 => '日式盤 02';

  @override
  String get plateJapanese04 => '日式盤 04';

  @override
  String get plateChina01 => '中式盤 01';

  @override
  String get plateChina02 => '中式盤 02';

  @override
  String get placeholderDash => '--';

  @override
  String valueWithCm(int value) {
    return '$value 公分';
  }

  @override
  String valueWithKg(int value) {
    return '$value 公斤';
  }

  @override
  String valueWithMl(int value) {
    return '$value 毫升';
  }

  @override
  String get referenceObjectLabel => '參考物';

  @override
  String get referenceObjectNone => '無';

  @override
  String get referenceObjectCard => '信用卡';

  @override
  String get referenceObjectCoin10 => '10 元硬幣';

  @override
  String get referenceObjectCoin5 => '5 元硬幣';

  @override
  String get referenceObjectManual => '測距（公分）';

  @override
  String get referenceLengthLabel => '測距長度（公分）';

  @override
  String get referenceLengthHint => '輸入 iOS 測距量到的公分';

  @override
  String get referenceLengthApply => '套用';

  @override
  String get tabChat => '聊天';

  @override
  String get tabChatAssistant => '咚咚';

  @override
  String get chatSettingsSection => '聊天設定';

  @override
  String get chatAssistantDefaultName => '咚咚';

  @override
  String get chatEmptyHint => '嗨，我是咚咚。你可以問我今天吃得怎麼樣，或下一餐怎麼安排。';

  @override
  String chatEmptyHintWithName(Object name) {
    return '嗨，我是$name。你可以問我今天吃得怎麼樣，或下一餐怎麼安排。';
  }

  @override
  String get chatInputHint => '問我今天怎麼吃...';

  @override
  String get chatLockedTitle => '訂閱後可開啟聊天陪伴';

  @override
  String get chatLockedBody => '開啟後可以直接問今天吃得如何、下一餐怎麼接，或請我幫你整理重點。';

  @override
  String get chatLockedAction => '查看訂閱';

  @override
  String get chatClearTitle => '清除聊天紀錄？';

  @override
  String get chatClearBody => '這會移除這台裝置上的對話內容。';

  @override
  String get chatClearConfirm => '清除';

  @override
  String get chatError => '聊天失敗，請稍後再試';

  @override
  String get chatErrorAuth => '登入已過期，請重新登入';

  @override
  String get chatErrorQuota => '今日聊天額度已用完，請稍後再試';

  @override
  String get chatErrorServer => '我這邊剛剛有點忙，稍後再試';

  @override
  String get chatErrorNetwork => '網路不穩定，請稍後再試';

  @override
  String get chatErrorReplyBase => '我剛剛沒整理好這次回答，稍後再問我一次好嗎？';

  @override
  String get chatErrorReasonPrefix => '原因：';

  @override
  String get chatErrorReasonAuth => '登入已過期或權限不足';

  @override
  String get chatErrorReasonQuota => '請求太頻繁或額度已用完';

  @override
  String get chatErrorReasonServer => '伺服器忙碌或暫時出錯';

  @override
  String get chatErrorReasonNetwork => '網路不穩定或連線中斷';

  @override
  String get chatErrorReasonUnknown => '暫時無法判斷';

  @override
  String get chatAvatarLabel => '聊天頭像';

  @override
  String get chatAssistantNameLabel => '助手名稱';

  @override
  String get chatAvatarSet => '已設定';

  @override
  String get chatAvatarUnset => '未設定';

  @override
  String get chatAvatarSheetTitle => '設定聊天頭像';

  @override
  String get chatAvatarPick => '選擇照片';

  @override
  String get chatAvatarRemove => '移除照片';

  @override
  String get authResetPasswordTitle => '重設密碼';

  @override
  String get authNewPasswordLabel => '新密碼';

  @override
  String get authPasswordRequired => '請輸入密碼';

  @override
  String get authPasswordUpdated => '密碼已更新';

  @override
  String get authResetPasswordAction => '更新密碼';

  @override
  String get authResetLinkInvalid => '連結已失效，請重新寄送重設密碼信';
}
