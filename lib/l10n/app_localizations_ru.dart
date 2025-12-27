// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Ailin Tattileri';

  @override
  String get welcomeTitle => 'Ailin Tattileri';

  @override
  String get welcomeSubtitle =>
      'Самые вкусные десерты и выпечка\nтеперь в вашем смартфоне!';

  @override
  String get yourCity => 'Ваш город:';

  @override
  String get cityZhetysay => 'Жетысай';

  @override
  String get deliveryWarning =>
      'В данный момент мы работаем и доставляем только по городу Жетысай.';

  @override
  String get locationCheck =>
      'Мы проверим ваше местоположение, чтобы убедиться, что сможем доставить заказ.';

  @override
  String get startShopping => 'Начать покупки';

  @override
  String get confirmAndEnter => 'Подтвердить и войти';

  @override
  String get justLooking => 'Просто посмотреть';

  @override
  String get locationErrorPrefix => 'Вы находитесь в';

  @override
  String get locationErrorSuffix =>
      'км от Жетысая. К сожалению, доставка недоступна.';

  @override
  String get homeGreeting => 'Привет, Гость';

  @override
  String get homeQuestion => 'Что хотите заказать?';

  @override
  String get search => 'Поиск...';

  @override
  String get menuMain => 'Главная';

  @override
  String get menuCart => 'Корзина';

  @override
  String get menuOrders => 'Заказы';

  @override
  String get menuProfile => 'Профиль';

  @override
  String get menuAdmin => 'Администрирование';

  @override
  String get menuAddProduct => 'Добавить товар';

  @override
  String get menuWorkers => 'Работники';

  @override
  String get menuShift => 'Моя смена';

  @override
  String get menuSalary => 'Зарплата';

  @override
  String get menuAdvance => 'Аванс';

  @override
  String get cartTitle => 'Корзина';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartClear => 'Очистить';

  @override
  String get cartTotal => 'Итого:';

  @override
  String get cartCheckout => 'Оформить заказ';

  @override
  String get deliveryUnavailable => 'Доставка недоступна';

  @override
  String get locationRestricted =>
      'Ваше местоположение вне зоны доставки (Жетысай)';

  @override
  String get checkoutTitle => 'Финальный шаг';

  @override
  String get checkoutName => 'Ваше имя';

  @override
  String get checkoutNameError => 'Введите имя';

  @override
  String get checkoutPhone => 'Телефон';

  @override
  String get checkoutPhoneError => 'Введите телефон';

  @override
  String get checkoutAddress => 'Адрес доставки';

  @override
  String get checkoutAddressError => 'Введите адрес';

  @override
  String get checkoutConfirm => 'Подтвердить заказ';

  @override
  String get orderSuccessTitle => 'Заказ принят! 🎉';

  @override
  String get orderSuccessMessage =>
      'Мы скоро свяжемся с вами для подтверждения.';

  @override
  String get great => 'Отлично';

  @override
  String get adminOrdersTitle => 'Заказы (Админ)';

  @override
  String get statusNew => 'Новый';

  @override
  String get statusAccepted => 'Принят';

  @override
  String get statusCooking => 'Готовится';

  @override
  String get statusDelivering => 'В пути';

  @override
  String get statusProcessing => 'В работе';

  @override
  String get statusCompleted => 'Выполнен';

  @override
  String get statusCancelled => 'Отменен';

  @override
  String get actionCancel => 'Отменить';

  @override
  String get actionAccept => 'Принять';

  @override
  String get actionComplete => 'Завершить заказ';

  @override
  String get orderLabel => 'Заказ:';

  @override
  String get addToCart => 'В корзину';

  @override
  String get ingredients => 'Состав';

  @override
  String get description => 'Описание';

  @override
  String get ordersEmpty => 'Заказов пока нет';

  @override
  String get addPhoto => 'Нажмите, чтобы добавить фото';

  @override
  String get productName => 'Название блюда';

  @override
  String get enterName => 'Введите название';

  @override
  String get productPrice => 'Цена (₸)';

  @override
  String get enterPrice => 'Введите цену';

  @override
  String get productCategory => 'Категория';

  @override
  String get productDescription => 'Описание (состав)';

  @override
  String get enterDescription => 'Введите описание';

  @override
  String get dashboard => 'Панель управления';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get favoritesEmpty => 'Избранное пусто';

  @override
  String get favoritesAddHint =>
      'Добавьте товары, которые вам нравятся, чтобы заказать их позже';

  @override
  String get removedFromFavorites => 'Удалено из избранного';

  @override
  String get addedToCart => 'добавлен в корзину';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmpty => 'Нет новых уведомлений';

  @override
  String get notificationsLoginRequired => 'Войдите, чтобы видеть уведомления';

  @override
  String get notificationsInfo =>
      'Мы оповестим вас о статусе заказов и специальных предложениях';

  @override
  String get readAll => 'Прочитать все';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryCakes => 'Торты';

  @override
  String get categoryCupcakes => 'Капкейки';

  @override
  String get categoryDrinks => 'Напитки';

  @override
  String get promoNew => '🔥 Новинка!';

  @override
  String get promoDiscountTitle => '20% Скидка\nНа первый заказ';

  @override
  String get promoDiscountCode => 'Код: CAKE20';

  @override
  String get promoDeliveryTag => '🚀 Доставка';

  @override
  String get promoDeliveryTitle => 'Бесплатная доставка\nот 5000 ₸';

  @override
  String get promoDeliverySubtitle => 'Быстро и Свежо';

  @override
  String get promoSpecialTag => '🧁 Акция';

  @override
  String get promoSpecialTitle => 'Набор из 6\nКапкейков';

  @override
  String get promoSpecialSubtitle => 'Всего 4500 ₸';

  @override
  String get productPriceLabel => 'Цена';

  @override
  String get productSoldOut => 'НЕТ В НАЛИЧИИ';

  @override
  String get notificationTypeOrder => 'Обновление заказа';

  @override
  String get notificationTypePromo => 'Специальное предложение';

  @override
  String get notificationTypeSecurity => 'Системное уведомление';

  @override
  String get notificationTypePayment => 'Оплата';

  @override
  String get notificationTypeAttendanceCheckIn => 'Приход на смену';

  @override
  String get notificationTypeAttendanceCheckOut => 'Завершение смены';

  @override
  String get guestUser => 'Гость';

  @override
  String get profileMySection => 'Мой профиль';

  @override
  String get profilePersonalData => 'Личные данные';

  @override
  String get profilePersonalSubtitle => 'Имя, Телефон, Адрес доставки';

  @override
  String get settingsSection => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get workerFinanceSection => 'Финансы';

  @override
  String get workerPayoutHistory => 'История выплат';

  @override
  String get adminSection => 'Администратор';

  @override
  String get logoutDialogTitle => 'Выход';

  @override
  String get logoutDialogContent => 'Вы уверены, что хотите выйти?';

  @override
  String get dialogNo => 'Нет';

  @override
  String get dialogYesLogout => 'Да, выйти';

  @override
  String get loginButton => 'Войти / Регистрация';

  @override
  String get logoutButton => 'Выйти';

  @override
  String get loadingError => 'Ошибка загрузки';

  @override
  String get orderStatusProcessingMessage => 'Ваш заказ принят в обработку';

  @override
  String get orderStatusReadyMessage => 'Ваш заказ готов к выдаче!';

  @override
  String get orderStatusCompletedMessage =>
      'Заказ выполнен! Спасибо за покупку';

  @override
  String get orderStatusCancelledMessage => 'Ваш заказ отменён';

  @override
  String get orderStatusDefaultMessage => 'Статус заказа изменён';

  @override
  String get notificationTitleNewOrder => 'Новый заказ';

  @override
  String notificationBodyNewOrder(Object amount) {
    return 'Поступил новый заказ на сумму $amount ₸';
  }

  @override
  String get adminDashboardTitle => 'Панель управления';

  @override
  String get statNewOrders => 'Новые заказы';

  @override
  String get statCompletedToday => 'Выполнено за сегодня';

  @override
  String get statTotalToday => 'Всего за сегодня';

  @override
  String get statRevenueToday => 'Выручка за сегодня';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get actionManageOrders => 'Управление заказами';

  @override
  String get actionManageOrdersSubtitle => 'Просмотр и обработка заказов';

  @override
  String get actionManageMenu => 'Управление меню';

  @override
  String get actionManageMenuSubtitle => 'Список товаров и редактирование';

  @override
  String get actionPayments => 'Выплаты';

  @override
  String get actionPaymentsSubtitle => 'Выплата зарплат работникам';

  @override
  String get actionAdvance => 'Выдать аванс';

  @override
  String get actionAdvanceSubtitle => 'Управление авансами и долгами';

  @override
  String get actionWarehouse => 'Склад';

  @override
  String get actionWarehouseSubtitle => 'Учёт ингредиентов (Beta)';

  @override
  String get actionExpenses => 'Расходы';

  @override
  String get actionExpensesSubtitle => 'Учёт расходов';

  @override
  String get actionAnalytics => 'Отчёты и аналитика';

  @override
  String get actionAnalyticsSubtitle => 'Статистика продаж';

  @override
  String get workersTitle => 'Работники';

  @override
  String get showQrCode => 'Показать общий QR-код';

  @override
  String get addWorker => 'Добавить работника';

  @override
  String get noWorkersForDate => 'Нет работников на этот день';

  @override
  String get workerName => 'Имя';

  @override
  String get workerPosition => 'Должность';

  @override
  String get workerPhone => 'Телефон';

  @override
  String get hourlyRate => 'Ставка за час (₸)';

  @override
  String get checkIn => 'Приход';

  @override
  String get checkOut => 'Уход';

  @override
  String get salaryShort => 'ЗП';

  @override
  String get deductionShort => 'Удерж';

  @override
  String get add => 'Добавить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get close => 'Закрыть';

  @override
  String get unlock => 'Разблокировка';

  @override
  String get enterUnlockCode => 'Введите код для редактирования:';

  @override
  String get code => 'Код';

  @override
  String get invalidCode => 'Неверный код';

  @override
  String get unlockAction => 'Разблокировать';

  @override
  String get lock => 'Заблокировать';

  @override
  String get scanQrCodeHint => 'Отсканируйте этот QR-код для отметки';

  @override
  String get checkInFirst => 'Сначала отметьте приход';

  @override
  String get hoursWorked => 'Отработано часов';

  @override
  String get hoursSuffix => 'ч';

  @override
  String get enterValidAmount => 'Введите корректную сумму';

  @override
  String get dailySalary => 'Зарплата за день';

  @override
  String get amountLabel => 'Сумма';

  @override
  String get enterAmount => 'Введите сумму';

  @override
  String get deductionAdvances => 'Удержано (Авансы):';

  @override
  String get toPay => 'К выплате:';

  @override
  String get checkInTime => 'Время прихода';

  @override
  String get checkOutTime => 'Время ухода';

  @override
  String get dataLockedHint =>
      'Данные заблокированы. Нажмите на замок для редактирования.';

  @override
  String get salarySavedNotificationSent =>
      'Зарплата сохранена и уведомление отправлено.';

  @override
  String get salarySavedNotificationFailed =>
      'Зарплата сохранена, но уведомление НЕ отправлено (нет токена).';

  @override
  String get salaryAccrualTitle => 'Начисление за смену';

  @override
  String salaryAccrualBody(Object amount, Object date) {
    return 'Вам начислено $amount ₸ за $date';
  }

  @override
  String get notMarked => 'Не отмечено';

  @override
  String get addProductTooltip => 'Добавить новый товар';

  @override
  String get searchProductHint => 'Поиск блюда...';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get editProductTitle => 'Редактировать товар';

  @override
  String get productUpdated => 'Товар успешно обновлен!';

  @override
  String get productAdded => 'Товар успешно добавлен!';

  @override
  String get errorImageUpload =>
      'Не удалось загрузить фото. Проверьте интернет.';

  @override
  String errorGeneric(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get deleteProductTitle => 'Удалить товар?';

  @override
  String deleteProductContent(Object productName) {
    return 'Вы уверены, что хотите удалить \'$productName\'?';
  }

  @override
  String get dataUpdated => 'Данные обновлены';

  @override
  String get itemsCountSuffix => 'товара';

  @override
  String get advanceTitle => 'Авансы';

  @override
  String get advanceTabActive => 'Активные';

  @override
  String get advanceTabHistory => 'История';

  @override
  String get advanceTabGive => 'Выдать';

  @override
  String get noActiveDebts => 'Активных долгов нет';

  @override
  String pendingLabel(Object count) {
    return 'Ожидает: $count';
  }

  @override
  String get activeDebt => 'Активный долг';

  @override
  String get debtSuffix => 'Долг';

  @override
  String get historyEmptyToday => 'История пуста за этот день';

  @override
  String advanceForWorker(Object name) {
    return 'Аванс для $name';
  }

  @override
  String get noteLabelOptional => 'Примечание (необязательно)';

  @override
  String get giveButton => 'Выдать';

  @override
  String get repaymentDialogTitle => 'Погашение долга';

  @override
  String get repaidFromSalary => 'Погашено с зарплаты';

  @override
  String get nothingOwed => 'Ничего не должен';

  @override
  String get repaymentAction => 'Погасить';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get advanceIssuedNotificationTitle => 'Начислен аванс';

  @override
  String advanceIssuedNotificationBody(Object amount) {
    return 'Вам начислен аванс в размере $amount ₸. Ожидайте выдачи или зачисления.';
  }

  @override
  String advanceRequestSent(Object name) {
    return 'Запрос отправлен $name. Ожидайте подтверждения.';
  }

  @override
  String errorOccurred(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get salaryNotFoundToday => 'Зарплата за сегодня не найдена';

  @override
  String get noDebtForWorker => 'У работника нет долга';

  @override
  String repaymentForWorker(Object name) {
    return 'Погашение: $name';
  }

  @override
  String get repaymentMethod => 'Способ погашения:';

  @override
  String get fromSalary => 'Из зарплаты';

  @override
  String get inCash => 'Наличными';

  @override
  String get repayFullDebt => 'Погасить весь долг';

  @override
  String get withholdFullSalary => 'Удержать всю зарплату';

  @override
  String remainingSalary(Object amount, Object balance) {
    return '$amount ₸ (Остаток зп: $balance ₸)';
  }

  @override
  String remainingDebt(Object amount, Object balance) {
    return '$amount ₸ (Остаток долга: $balance ₸)';
  }

  @override
  String get partialOrOtherAmount => 'Частично / Другая сумма';

  @override
  String get amountLabelWithCurrency => 'Сумма (₸)';

  @override
  String get amountHintExample => 'Например: 5 000';

  @override
  String get fullDebtRepaymentFromSalary =>
      'Полное погашение долга из зарплаты';

  @override
  String get fullSalaryWithholding => 'Удержание всей зарплаты';

  @override
  String get partOfSalary => 'Часть зарплаты';

  @override
  String get cashRepayment => 'Возврат наличными';

  @override
  String debtReducedNotificationBody(Object amount, Object note) {
    return 'Ваш долг уменьшен на $amount ₸. ($note)';
  }

  @override
  String reaidAmount(Object amount) {
    return 'Погашено: $amount ₸';
  }

  @override
  String get repayButton => 'Погасить';

  @override
  String get takenAmount => 'Взято';

  @override
  String get repaidAmountLabel => 'Погашено';

  @override
  String get repayment => 'Погашение';

  @override
  String get advance => 'Аванс';

  @override
  String get pendingStatus => 'Ожидает';

  @override
  String get rejectedStatus => 'Отклонен';

  @override
  String repaidAmount(Object amount) {
    return 'Погашено: $amount ₸';
  }

  @override
  String get paymentsTitle => 'Выплаты зарплат';

  @override
  String get paymentTabToPay => 'К выплате';

  @override
  String get paymentTabPending => 'Ожидают';

  @override
  String get paymentTabHistory => 'История';

  @override
  String paymentForWorker(Object name) {
    return 'Выплата: $name';
  }

  @override
  String currentDebtWithPending(Object amount) {
    return 'Текущий долг (с учетом ожидающих): $amount ₸';
  }

  @override
  String totalInDatabase(Object amount) {
    return '(Всего в базе: $amount ₸)';
  }

  @override
  String get paymentAmountLabel => 'Сумма выплаты';

  @override
  String get payButton => 'Выплатить';

  @override
  String get paymentSentNotificationTitle => 'Вам отправлена выплата';

  @override
  String paymentSentNotificationBody(Object amount) {
    return 'Подтвердите получение $amount ₸';
  }

  @override
  String paymentSentSuccess(Object amount, Object name) {
    return 'Выплата $amount ₸ отправлена $name. Ожидает подтверждения.';
  }

  @override
  String pendingConfirmationLabel(Object amount) {
    return 'Ожидает подтв.: $amount ₸';
  }

  @override
  String get unpaidWorkersTitle => 'Нет работников к выплате';

  @override
  String get pendingPaymentsTitle => 'Нет ожидающих выплат';

  @override
  String get paymentHistoryTitle => 'Нет истории выплат';

  @override
  String get expensesTitle => 'Расходы';

  @override
  String get addExpense => 'Добавить расход';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get categoryProducts => 'Продукты';

  @override
  String get categoryTransport => 'Транспорт';

  @override
  String get categoryEquipment => 'Оборудование';

  @override
  String get categoryCommunal => 'Коммунальное';

  @override
  String get categorySalary => 'Зарплата/Аванс';

  @override
  String get categoryOther => 'Другое';

  @override
  String get expenseAdded => 'Расход успешно добавлен!';

  @override
  String totalForDay(Object amount) {
    return 'Итого за день: $amount ₸';
  }

  @override
  String get noExpensesToday => 'Нет расходов за этот день';

  @override
  String get warehouseTitle => 'Склад';

  @override
  String get allIngredients => 'Все ингредиенты';

  @override
  String get lowStock => 'Мало на складе';

  @override
  String get searchIngredients => 'Поиск ингредиентов...';

  @override
  String get addIngredient => 'Добавить ингредиент';

  @override
  String get editIngredient => 'Редактировать ингредиент';

  @override
  String get unitLabel => 'Ед. изм. (кг, л, шт)';

  @override
  String get minStockLabel => 'Мин. остаток';

  @override
  String get updateStock => 'Обновить остаток';

  @override
  String get stockArrival => 'Приход';

  @override
  String get stockExpense => 'Расход';

  @override
  String get unitPriceLabel => 'Цена за ед. изм.';

  @override
  String get transactionsTitle => 'Транзакции';

  @override
  String get historyTitle => 'История операций';

  @override
  String get noIngredientsFound => 'Ингредиенты не найдены';

  @override
  String get ingredientSaved => 'Сохранено!';

  @override
  String get nameLabel => 'Название';

  @override
  String get quantityLabel => 'Количество';

  @override
  String get noteLabel => 'Примечание';

  @override
  String get writeOff => 'Списать';

  @override
  String get inventory => 'Остатки';

  @override
  String get history => 'История';

  @override
  String get totalExpenses => 'Всего расходов';

  @override
  String get generalQrTitle => 'Общий QR-код';

  @override
  String get qrPrintHint =>
      'Распечатайте этот QR-код и повесьте на кухне. Работники будут сканировать его при приходе и уходе.';

  @override
  String get qrForCheckIn => 'QR-код для отметки';

  @override
  String get scanForCheckInOut => 'Сканируйте для прихода и ухода';

  @override
  String get manualCodeLabel => 'Код для ручного ввода';

  @override
  String get workerInstructionTitle => 'Инструкция для работников';

  @override
  String get workerStep1 => '1. Откройте приложение Ailin Tattileri';

  @override
  String get workerStep2 => '2. Нажмите \'Сканировать QR\' на главном экране';

  @override
  String get workerStep3 => '3. Наведите камеру на этот код';

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get thisMonth => 'Этот месяц';

  @override
  String get pickPeriod => 'Выбрать период';

  @override
  String get revenue => 'Выручка';

  @override
  String get ordersCount => 'Заказов';

  @override
  String get totalExpensesLabel => 'Расходы';

  @override
  String get netProfit => 'Чистая прибыль';

  @override
  String get revenueDynamics => 'Динамика выручки';

  @override
  String get topProducts => 'Топ товаров';

  @override
  String get byPopularity => 'по популярности';

  @override
  String get ordersLabel => 'Заказы';

  @override
  String get quantityShort => 'Кол-во';

  @override
  String get noData => 'Нет данных';

  @override
  String get finance => 'Финансы';

  @override
  String get totalSalariesLabel => 'Зарплаты';

  @override
  String get averageCheck => 'Средний чек';

  @override
  String get noDataForPeriod => 'Нет данных за этот период';

  @override
  String get workerDashboardTitle => 'Моя смена';

  @override
  String get loginRequired => 'Войдите в систему';

  @override
  String get notRegisteredAsWorker => 'Вы не зарегистрированы как работник';

  @override
  String get scanQr => 'Сканировать QR';

  @override
  String get checkInTimeLabel => 'Время прихода';

  @override
  String get checkOutTimeLabel => 'Время ухода';

  @override
  String get hoursWorkedLabel => 'Отработано часов';

  @override
  String get earned => 'Заработано';

  @override
  String get advanceRepayment => 'Погашение аванса';

  @override
  String get totalToPay => 'Итого к выдаче';

  @override
  String get total => 'Итого';

  @override
  String get ok => 'ОК';

  @override
  String get scanForCheckIn => 'Отсканируйте для начала смены';

  @override
  String get scanForCheckOut => 'Отсканируйте для завершения смены';

  @override
  String get shiftCompleted => 'Смена завершена';

  @override
  String get myAdvances => 'Мои Авансы';

  @override
  String get currentDebt => 'Текущий долг';

  @override
  String get debtRepayment => 'Погашение долга';

  @override
  String get pending => 'Ожидает';

  @override
  String get accepted => 'Принято';

  @override
  String get rejected => 'Отклонено';

  @override
  String get reject => 'Отказаться';

  @override
  String get accept => 'Принять';

  @override
  String get advanceAccepted => 'Аванс принят ✅';

  @override
  String get advanceRejected => 'Аванс отклонен 🚫';

  @override
  String get salaryHistory => 'История зарплат';

  @override
  String get noWorkerData => 'Нет данных о работнике';

  @override
  String get historyEmpty => 'История пуста';

  @override
  String get noSalariesYet => 'Зарплат пока нет';

  @override
  String hoursWorkedShort(Object hours) {
    return '$hours ч. работы';
  }

  @override
  String get deducted => 'Удержано';

  @override
  String outOf(Object total) {
    return 'из $total';
  }

  @override
  String get invalidQrCode =>
      'Неверный QR-код. Используйте общий QR-код кухни.';

  @override
  String get alreadyCheckedOut => 'Вы уже отметили уход сегодня';

  @override
  String get checkInMarked => '✓ Приход отмечен';

  @override
  String get checkOutMarked => '✓ Уход отмечен';

  @override
  String get attendanceCheckInTitle => 'Приход на смену 🟢';

  @override
  String get attendanceCheckOutTitle => 'Завершение смены 🏁';

  @override
  String beganWork(Object name, Object time) {
    return '$name начал работу в $time';
  }

  @override
  String finishedWork(Object hours, Object name) {
    return '$name завершил работу. Отработано: $hours ч';
  }

  @override
  String get scanQrInstruction => 'Наведите камеру на общий QR-код';

  @override
  String get repayments => 'Погашения';

  @override
  String get pendingAdvances => 'Ожидающие авансы';

  @override
  String get advanceHistory => 'История авансов';

  @override
  String get noAdvancesOrRepayments => 'Авансов или погашений пока нет';

  @override
  String get paymentHistory => 'История выплат';

  @override
  String get currentBalance => 'Текущий баланс (Невыплачено)';

  @override
  String get operationHistory => 'История операций';

  @override
  String get paymentHistoryEmpty => 'История выплат пуста';

  @override
  String get paymentConfirmedSuccess => 'Спасибо! Получение подтверждено.';

  @override
  String get error => 'Ошибка';

  @override
  String get confirmReceipt => 'Подтвердить получение';

  @override
  String get orderPlaced => 'Заказ оформлен!';

  @override
  String get orderPaymentUponPickup =>
      'Оплата производится при получении заказа в точке самовывоза';

  @override
  String get orderNumber => 'Номер заказа';

  @override
  String get orderStatus => 'Статус';

  @override
  String get orderStatusAwaitingPayment => 'Ожидает оплаты';

  @override
  String get deliveryType => 'Тип доставки';

  @override
  String get pickup => 'Самовывоз';

  @override
  String get delivery => 'Доставка';

  @override
  String get pickupPoint => 'Точка самовывоза';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get readiness => 'Готовность';

  @override
  String get deliveryTime => 'Время доставки';

  @override
  String get totalAmount => 'Итоговая сумма';

  @override
  String get goToMyOrders => 'Перейти к моим заказам';

  @override
  String get returnToMain => 'Вернуться на главную';
}
