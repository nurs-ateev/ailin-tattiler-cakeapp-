import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ailin Tattileri'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ailin Tattileri'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Самые вкусные десерты и выпечка\nтеперь в вашем смартфоне!'**
  String get welcomeSubtitle;

  /// No description provided for @yourCity.
  ///
  /// In ru, this message translates to:
  /// **'Ваш город:'**
  String get yourCity;

  /// No description provided for @cityZhetysay.
  ///
  /// In ru, this message translates to:
  /// **'Жетысай'**
  String get cityZhetysay;

  /// No description provided for @deliveryWarning.
  ///
  /// In ru, this message translates to:
  /// **'В данный момент мы работаем и доставляем только по городу Жетысай.'**
  String get deliveryWarning;

  /// No description provided for @locationCheck.
  ///
  /// In ru, this message translates to:
  /// **'Мы проверим ваше местоположение, чтобы убедиться, что сможем доставить заказ.'**
  String get locationCheck;

  /// No description provided for @startShopping.
  ///
  /// In ru, this message translates to:
  /// **'Начать покупки'**
  String get startShopping;

  /// No description provided for @confirmAndEnter.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить и войти'**
  String get confirmAndEnter;

  /// No description provided for @justLooking.
  ///
  /// In ru, this message translates to:
  /// **'Просто посмотреть'**
  String get justLooking;

  /// No description provided for @locationErrorPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Вы находитесь в'**
  String get locationErrorPrefix;

  /// No description provided for @locationErrorSuffix.
  ///
  /// In ru, this message translates to:
  /// **'км от Жетысая. К сожалению, доставка недоступна.'**
  String get locationErrorSuffix;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Привет, Гость'**
  String get homeGreeting;

  /// No description provided for @homeQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Что хотите заказать?'**
  String get homeQuestion;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get search;

  /// No description provided for @menuMain.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get menuMain;

  /// No description provided for @menuCart.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get menuCart;

  /// No description provided for @menuOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get menuOrders;

  /// No description provided for @menuProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get menuProfile;

  /// No description provided for @menuAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Администрирование'**
  String get menuAdmin;

  /// No description provided for @menuAddProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар'**
  String get menuAddProduct;

  /// No description provided for @menuWorkers.
  ///
  /// In ru, this message translates to:
  /// **'Работники'**
  String get menuWorkers;

  /// No description provided for @menuShift.
  ///
  /// In ru, this message translates to:
  /// **'Моя смена'**
  String get menuShift;

  /// No description provided for @menuSalary.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата'**
  String get menuSalary;

  /// No description provided for @menuAdvance.
  ///
  /// In ru, this message translates to:
  /// **'Аванс'**
  String get menuAdvance;

  /// No description provided for @cartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста'**
  String get cartEmpty;

  /// No description provided for @cartClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get cartClear;

  /// No description provided for @cartTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого:'**
  String get cartTotal;

  /// No description provided for @cartCheckout.
  ///
  /// In ru, this message translates to:
  /// **'Оформить заказ'**
  String get cartCheckout;

  /// No description provided for @deliveryUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Доставка недоступна'**
  String get deliveryUnavailable;

  /// No description provided for @locationRestricted.
  ///
  /// In ru, this message translates to:
  /// **'Ваше местоположение вне зоны доставки (Жетысай)'**
  String get locationRestricted;

  /// No description provided for @checkoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Финальный шаг'**
  String get checkoutTitle;

  /// No description provided for @checkoutName.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get checkoutName;

  /// No description provided for @checkoutNameError.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get checkoutNameError;

  /// No description provided for @checkoutPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get checkoutPhone;

  /// No description provided for @checkoutPhoneError.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон'**
  String get checkoutPhoneError;

  /// No description provided for @checkoutAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get checkoutAddress;

  /// No description provided for @checkoutAddressError.
  ///
  /// In ru, this message translates to:
  /// **'Введите адрес'**
  String get checkoutAddressError;

  /// No description provided for @checkoutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить заказ'**
  String get checkoutConfirm;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ принят! 🎉'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In ru, this message translates to:
  /// **'Мы скоро свяжемся с вами для подтверждения.'**
  String get orderSuccessMessage;

  /// No description provided for @great.
  ///
  /// In ru, this message translates to:
  /// **'Отлично'**
  String get great;

  /// No description provided for @adminOrdersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказы (Админ)'**
  String get adminOrdersTitle;

  /// No description provided for @statusNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый'**
  String get statusNew;

  /// No description provided for @statusAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get statusAccepted;

  /// No description provided for @statusCooking.
  ///
  /// In ru, this message translates to:
  /// **'Готовится'**
  String get statusCooking;

  /// No description provided for @statusDelivering.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get statusDelivering;

  /// No description provided for @statusProcessing.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get statusProcessing;

  /// No description provided for @statusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Выполнен'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменен'**
  String get statusCancelled;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get actionCancel;

  /// No description provided for @actionAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get actionAccept;

  /// No description provided for @actionComplete.
  ///
  /// In ru, this message translates to:
  /// **'Завершить заказ'**
  String get actionComplete;

  /// No description provided for @orderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Заказ:'**
  String get orderLabel;

  /// No description provided for @addToCart.
  ///
  /// In ru, this message translates to:
  /// **'В корзину'**
  String get addToCart;

  /// No description provided for @ingredients.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get ingredients;

  /// No description provided for @description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// No description provided for @ordersEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заказов пока нет'**
  String get ordersEmpty;

  /// No description provided for @addPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы добавить фото'**
  String get addPhoto;

  /// No description provided for @productName.
  ///
  /// In ru, this message translates to:
  /// **'Название блюда'**
  String get productName;

  /// No description provided for @enterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get enterName;

  /// No description provided for @productPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена (₸)'**
  String get productPrice;

  /// No description provided for @enterPrice.
  ///
  /// In ru, this message translates to:
  /// **'Введите цену'**
  String get enterPrice;

  /// No description provided for @productCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get productCategory;

  /// No description provided for @productDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание (состав)'**
  String get productDescription;

  /// No description provided for @enterDescription.
  ///
  /// In ru, this message translates to:
  /// **'Введите описание'**
  String get enterDescription;

  /// No description provided for @dashboard.
  ///
  /// In ru, this message translates to:
  /// **'Панель управления'**
  String get dashboard;

  /// No description provided for @favoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Избранное пусто'**
  String get favoritesEmpty;

  /// No description provided for @favoritesAddHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары, которые вам нравятся, чтобы заказать их позже'**
  String get favoritesAddHint;

  /// No description provided for @removedFromFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из избранного'**
  String get removedFromFavorites;

  /// No description provided for @addedToCart.
  ///
  /// In ru, this message translates to:
  /// **'добавлен в корзину'**
  String get addedToCart;

  /// No description provided for @notificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет новых уведомлений'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoginRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы видеть уведомления'**
  String get notificationsLoginRequired;

  /// No description provided for @notificationsInfo.
  ///
  /// In ru, this message translates to:
  /// **'Мы оповестим вас о статусе заказов и специальных предложениях'**
  String get notificationsInfo;

  /// No description provided for @readAll.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get readAll;

  /// No description provided for @categoryAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get categoryAll;

  /// No description provided for @categoryCakes.
  ///
  /// In ru, this message translates to:
  /// **'Торты'**
  String get categoryCakes;

  /// No description provided for @categoryCupcakes.
  ///
  /// In ru, this message translates to:
  /// **'Капкейки'**
  String get categoryCupcakes;

  /// No description provided for @categoryDrinks.
  ///
  /// In ru, this message translates to:
  /// **'Напитки'**
  String get categoryDrinks;

  /// No description provided for @promoNew.
  ///
  /// In ru, this message translates to:
  /// **'🔥 Новинка!'**
  String get promoNew;

  /// No description provided for @promoDiscountTitle.
  ///
  /// In ru, this message translates to:
  /// **'20% Скидка\nНа первый заказ'**
  String get promoDiscountTitle;

  /// No description provided for @promoDiscountCode.
  ///
  /// In ru, this message translates to:
  /// **'Код: CAKE20'**
  String get promoDiscountCode;

  /// No description provided for @promoDeliveryTag.
  ///
  /// In ru, this message translates to:
  /// **'🚀 Доставка'**
  String get promoDeliveryTag;

  /// No description provided for @promoDeliveryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная доставка\nот 5000 ₸'**
  String get promoDeliveryTitle;

  /// No description provided for @promoDeliverySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Быстро и Свежо'**
  String get promoDeliverySubtitle;

  /// No description provided for @promoSpecialTag.
  ///
  /// In ru, this message translates to:
  /// **'🧁 Акция'**
  String get promoSpecialTag;

  /// No description provided for @promoSpecialTitle.
  ///
  /// In ru, this message translates to:
  /// **'Набор из 6\nКапкейков'**
  String get promoSpecialTitle;

  /// No description provided for @promoSpecialSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Всего 4500 ₸'**
  String get promoSpecialSubtitle;

  /// No description provided for @productPriceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get productPriceLabel;

  /// No description provided for @productSoldOut.
  ///
  /// In ru, this message translates to:
  /// **'НЕТ В НАЛИЧИИ'**
  String get productSoldOut;

  /// No description provided for @notificationTypeOrder.
  ///
  /// In ru, this message translates to:
  /// **'Обновление заказа'**
  String get notificationTypeOrder;

  /// No description provided for @notificationTypePromo.
  ///
  /// In ru, this message translates to:
  /// **'Специальное предложение'**
  String get notificationTypePromo;

  /// No description provided for @notificationTypeSecurity.
  ///
  /// In ru, this message translates to:
  /// **'Системное уведомление'**
  String get notificationTypeSecurity;

  /// No description provided for @notificationTypePayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get notificationTypePayment;

  /// No description provided for @notificationTypeAttendanceCheckIn.
  ///
  /// In ru, this message translates to:
  /// **'Приход на смену'**
  String get notificationTypeAttendanceCheckIn;

  /// No description provided for @notificationTypeAttendanceCheckOut.
  ///
  /// In ru, this message translates to:
  /// **'Завершение смены'**
  String get notificationTypeAttendanceCheckOut;

  /// No description provided for @guestUser.
  ///
  /// In ru, this message translates to:
  /// **'Гость'**
  String get guestUser;

  /// No description provided for @profileMySection.
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль'**
  String get profileMySection;

  /// No description provided for @profilePersonalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get profilePersonalData;

  /// No description provided for @profilePersonalSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Имя, Телефон, Адрес доставки'**
  String get profilePersonalSubtitle;

  /// No description provided for @settingsSection.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Темная'**
  String get themeDark;

  /// No description provided for @workerFinanceSection.
  ///
  /// In ru, this message translates to:
  /// **'Финансы'**
  String get workerFinanceSection;

  /// No description provided for @workerPayoutHistory.
  ///
  /// In ru, this message translates to:
  /// **'История выплат'**
  String get workerPayoutHistory;

  /// No description provided for @adminSection.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get adminSection;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogContent.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти?'**
  String get logoutDialogContent;

  /// No description provided for @dialogNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get dialogNo;

  /// No description provided for @dialogYesLogout.
  ///
  /// In ru, this message translates to:
  /// **'Да, выйти'**
  String get dialogYesLogout;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти / Регистрация'**
  String get loginButton;

  /// No description provided for @logoutButton.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logoutButton;

  /// No description provided for @loadingError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get loadingError;

  /// No description provided for @orderStatusProcessingMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ принят в обработку'**
  String get orderStatusProcessingMessage;

  /// No description provided for @orderStatusReadyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ готов к выдаче!'**
  String get orderStatusReadyMessage;

  /// No description provided for @orderStatusCompletedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Заказ выполнен! Спасибо за покупку'**
  String get orderStatusCompletedMessage;

  /// No description provided for @orderStatusCancelledMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ отменён'**
  String get orderStatusCancelledMessage;

  /// No description provided for @orderStatusDefaultMessage.
  ///
  /// In ru, this message translates to:
  /// **'Статус заказа изменён'**
  String get orderStatusDefaultMessage;

  /// No description provided for @notificationTitleNewOrder.
  ///
  /// In ru, this message translates to:
  /// **'Новый заказ'**
  String get notificationTitleNewOrder;

  /// No description provided for @notificationBodyNewOrder.
  ///
  /// In ru, this message translates to:
  /// **'Поступил новый заказ на сумму {amount} ₸'**
  String notificationBodyNewOrder(Object amount);

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Панель управления'**
  String get adminDashboardTitle;

  /// No description provided for @statNewOrders.
  ///
  /// In ru, this message translates to:
  /// **'Новые заказы'**
  String get statNewOrders;

  /// No description provided for @statCompletedToday.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено за сегодня'**
  String get statCompletedToday;

  /// No description provided for @statTotalToday.
  ///
  /// In ru, this message translates to:
  /// **'Всего за сегодня'**
  String get statTotalToday;

  /// No description provided for @statRevenueToday.
  ///
  /// In ru, this message translates to:
  /// **'Выручка за сегодня'**
  String get statRevenueToday;

  /// No description provided for @quickActions.
  ///
  /// In ru, this message translates to:
  /// **'Быстрые действия'**
  String get quickActions;

  /// No description provided for @actionManageOrders.
  ///
  /// In ru, this message translates to:
  /// **'Управление заказами'**
  String get actionManageOrders;

  /// No description provided for @actionManageOrdersSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр и обработка заказов'**
  String get actionManageOrdersSubtitle;

  /// No description provided for @actionManageMenu.
  ///
  /// In ru, this message translates to:
  /// **'Управление меню'**
  String get actionManageMenu;

  /// No description provided for @actionManageMenuSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Список товаров и редактирование'**
  String get actionManageMenuSubtitle;

  /// No description provided for @actionPayments.
  ///
  /// In ru, this message translates to:
  /// **'Выплаты'**
  String get actionPayments;

  /// No description provided for @actionPaymentsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выплата зарплат работникам'**
  String get actionPaymentsSubtitle;

  /// No description provided for @actionAdvance.
  ///
  /// In ru, this message translates to:
  /// **'Выдать аванс'**
  String get actionAdvance;

  /// No description provided for @actionAdvanceSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Управление авансами и долгами'**
  String get actionAdvanceSubtitle;

  /// No description provided for @actionWarehouse.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get actionWarehouse;

  /// No description provided for @actionWarehouseSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Учёт ингредиентов (Beta)'**
  String get actionWarehouseSubtitle;

  /// No description provided for @actionExpenses.
  ///
  /// In ru, this message translates to:
  /// **'Расходы'**
  String get actionExpenses;

  /// No description provided for @actionExpensesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Учёт расходов'**
  String get actionExpensesSubtitle;

  /// No description provided for @actionAnalytics.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты и аналитика'**
  String get actionAnalytics;

  /// No description provided for @actionAnalyticsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Статистика продаж'**
  String get actionAnalyticsSubtitle;

  /// No description provided for @workersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Работники'**
  String get workersTitle;

  /// No description provided for @showQrCode.
  ///
  /// In ru, this message translates to:
  /// **'Показать общий QR-код'**
  String get showQrCode;

  /// No description provided for @addWorker.
  ///
  /// In ru, this message translates to:
  /// **'Добавить работника'**
  String get addWorker;

  /// No description provided for @noWorkersForDate.
  ///
  /// In ru, this message translates to:
  /// **'Нет работников на этот день'**
  String get noWorkersForDate;

  /// No description provided for @workerName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get workerName;

  /// No description provided for @workerPosition.
  ///
  /// In ru, this message translates to:
  /// **'Должность'**
  String get workerPosition;

  /// No description provided for @workerPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get workerPhone;

  /// No description provided for @hourlyRate.
  ///
  /// In ru, this message translates to:
  /// **'Ставка за час (₸)'**
  String get hourlyRate;

  /// No description provided for @checkIn.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In ru, this message translates to:
  /// **'Уход'**
  String get checkOut;

  /// No description provided for @salaryShort.
  ///
  /// In ru, this message translates to:
  /// **'ЗП'**
  String get salaryShort;

  /// No description provided for @deductionShort.
  ///
  /// In ru, this message translates to:
  /// **'Удерж'**
  String get deductionShort;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @unlock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировка'**
  String get unlock;

  /// No description provided for @enterUnlockCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите код для редактирования:'**
  String get enterUnlockCode;

  /// No description provided for @code.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get code;

  /// No description provided for @invalidCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get invalidCode;

  /// No description provided for @unlockAction.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get unlockAction;

  /// No description provided for @lock.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get lock;

  /// No description provided for @scanQrCodeHint.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте этот QR-код для отметки'**
  String get scanQrCodeHint;

  /// No description provided for @checkInFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала отметьте приход'**
  String get checkInFirst;

  /// No description provided for @hoursWorked.
  ///
  /// In ru, this message translates to:
  /// **'Отработано часов'**
  String get hoursWorked;

  /// No description provided for @hoursSuffix.
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get hoursSuffix;

  /// No description provided for @enterValidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректную сумму'**
  String get enterValidAmount;

  /// No description provided for @dailySalary.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата за день'**
  String get dailySalary;

  /// No description provided for @amountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get amountLabel;

  /// No description provided for @enterAmount.
  ///
  /// In ru, this message translates to:
  /// **'Введите сумму'**
  String get enterAmount;

  /// No description provided for @deductionAdvances.
  ///
  /// In ru, this message translates to:
  /// **'Удержано (Авансы):'**
  String get deductionAdvances;

  /// No description provided for @toPay.
  ///
  /// In ru, this message translates to:
  /// **'К выплате:'**
  String get toPay;

  /// No description provided for @checkInTime.
  ///
  /// In ru, this message translates to:
  /// **'Время прихода'**
  String get checkInTime;

  /// No description provided for @checkOutTime.
  ///
  /// In ru, this message translates to:
  /// **'Время ухода'**
  String get checkOutTime;

  /// No description provided for @dataLockedHint.
  ///
  /// In ru, this message translates to:
  /// **'Данные заблокированы. Нажмите на замок для редактирования.'**
  String get dataLockedHint;

  /// No description provided for @salarySavedNotificationSent.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата сохранена и уведомление отправлено.'**
  String get salarySavedNotificationSent;

  /// No description provided for @salarySavedNotificationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата сохранена, но уведомление НЕ отправлено (нет токена).'**
  String get salarySavedNotificationFailed;

  /// No description provided for @salaryAccrualTitle.
  ///
  /// In ru, this message translates to:
  /// **'Начисление за смену'**
  String get salaryAccrualTitle;

  /// No description provided for @salaryAccrualBody.
  ///
  /// In ru, this message translates to:
  /// **'Вам начислено {amount} ₸ за {date}'**
  String salaryAccrualBody(Object amount, Object date);

  /// No description provided for @notMarked.
  ///
  /// In ru, this message translates to:
  /// **'Не отмечено'**
  String get notMarked;

  /// No description provided for @addProductTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Добавить новый товар'**
  String get addProductTooltip;

  /// No description provided for @searchProductHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск блюда...'**
  String get searchProductHint;

  /// No description provided for @nothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get nothingFound;

  /// No description provided for @editProductTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать товар'**
  String get editProductTitle;

  /// No description provided for @productUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Товар успешно обновлен!'**
  String get productUpdated;

  /// No description provided for @productAdded.
  ///
  /// In ru, this message translates to:
  /// **'Товар успешно добавлен!'**
  String get productAdded;

  /// No description provided for @errorImageUpload.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото. Проверьте интернет.'**
  String get errorImageUpload;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @deleteProductTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductContent.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить \'{productName}\'?'**
  String deleteProductContent(Object productName);

  /// No description provided for @dataUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Данные обновлены'**
  String get dataUpdated;

  /// No description provided for @itemsCountSuffix.
  ///
  /// In ru, this message translates to:
  /// **'товара'**
  String get itemsCountSuffix;

  /// No description provided for @advanceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Авансы'**
  String get advanceTitle;

  /// No description provided for @advanceTabActive.
  ///
  /// In ru, this message translates to:
  /// **'Активные'**
  String get advanceTabActive;

  /// No description provided for @advanceTabHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get advanceTabHistory;

  /// No description provided for @advanceTabGive.
  ///
  /// In ru, this message translates to:
  /// **'Выдать'**
  String get advanceTabGive;

  /// No description provided for @noActiveDebts.
  ///
  /// In ru, this message translates to:
  /// **'Активных долгов нет'**
  String get noActiveDebts;

  /// No description provided for @pendingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает: {count}'**
  String pendingLabel(Object count);

  /// No description provided for @activeDebt.
  ///
  /// In ru, this message translates to:
  /// **'Активный долг'**
  String get activeDebt;

  /// No description provided for @debtSuffix.
  ///
  /// In ru, this message translates to:
  /// **'Долг'**
  String get debtSuffix;

  /// No description provided for @historyEmptyToday.
  ///
  /// In ru, this message translates to:
  /// **'История пуста за этот день'**
  String get historyEmptyToday;

  /// No description provided for @advanceForWorker.
  ///
  /// In ru, this message translates to:
  /// **'Аванс для {name}'**
  String advanceForWorker(Object name);

  /// No description provided for @noteLabelOptional.
  ///
  /// In ru, this message translates to:
  /// **'Примечание (необязательно)'**
  String get noteLabelOptional;

  /// No description provided for @giveButton.
  ///
  /// In ru, this message translates to:
  /// **'Выдать'**
  String get giveButton;

  /// No description provided for @repaymentDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долга'**
  String get repaymentDialogTitle;

  /// No description provided for @repaidFromSalary.
  ///
  /// In ru, this message translates to:
  /// **'Погашено с зарплаты'**
  String get repaidFromSalary;

  /// No description provided for @nothingOwed.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не должен'**
  String get nothingOwed;

  /// No description provided for @repaymentAction.
  ///
  /// In ru, this message translates to:
  /// **'Погасить'**
  String get repaymentAction;

  /// No description provided for @cancelButton.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancelButton;

  /// No description provided for @advanceIssuedNotificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Начислен аванс'**
  String get advanceIssuedNotificationTitle;

  /// No description provided for @advanceIssuedNotificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Вам начислен аванс в размере {amount} ₸. Ожидайте выдачи или зачисления.'**
  String advanceIssuedNotificationBody(Object amount);

  /// No description provided for @advanceRequestSent.
  ///
  /// In ru, this message translates to:
  /// **'Запрос отправлен {name}. Ожидайте подтверждения.'**
  String advanceRequestSent(Object name);

  /// No description provided for @errorOccurred.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String errorOccurred(Object error);

  /// No description provided for @salaryNotFoundToday.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата за сегодня не найдена'**
  String get salaryNotFoundToday;

  /// No description provided for @noDebtForWorker.
  ///
  /// In ru, this message translates to:
  /// **'У работника нет долга'**
  String get noDebtForWorker;

  /// No description provided for @repaymentForWorker.
  ///
  /// In ru, this message translates to:
  /// **'Погашение: {name}'**
  String repaymentForWorker(Object name);

  /// No description provided for @repaymentMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ погашения:'**
  String get repaymentMethod;

  /// No description provided for @fromSalary.
  ///
  /// In ru, this message translates to:
  /// **'Из зарплаты'**
  String get fromSalary;

  /// No description provided for @inCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличными'**
  String get inCash;

  /// No description provided for @repayFullDebt.
  ///
  /// In ru, this message translates to:
  /// **'Погасить весь долг'**
  String get repayFullDebt;

  /// No description provided for @withholdFullSalary.
  ///
  /// In ru, this message translates to:
  /// **'Удержать всю зарплату'**
  String get withholdFullSalary;

  /// No description provided for @remainingSalary.
  ///
  /// In ru, this message translates to:
  /// **'{amount} ₸ (Остаток зп: {balance} ₸)'**
  String remainingSalary(Object amount, Object balance);

  /// No description provided for @remainingDebt.
  ///
  /// In ru, this message translates to:
  /// **'{amount} ₸ (Остаток долга: {balance} ₸)'**
  String remainingDebt(Object amount, Object balance);

  /// No description provided for @partialOrOtherAmount.
  ///
  /// In ru, this message translates to:
  /// **'Частично / Другая сумма'**
  String get partialOrOtherAmount;

  /// No description provided for @amountLabelWithCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Сумма (₸)'**
  String get amountLabelWithCurrency;

  /// No description provided for @amountHintExample.
  ///
  /// In ru, this message translates to:
  /// **'Например: 5 000'**
  String get amountHintExample;

  /// No description provided for @fullDebtRepaymentFromSalary.
  ///
  /// In ru, this message translates to:
  /// **'Полное погашение долга из зарплаты'**
  String get fullDebtRepaymentFromSalary;

  /// No description provided for @fullSalaryWithholding.
  ///
  /// In ru, this message translates to:
  /// **'Удержание всей зарплаты'**
  String get fullSalaryWithholding;

  /// No description provided for @partOfSalary.
  ///
  /// In ru, this message translates to:
  /// **'Часть зарплаты'**
  String get partOfSalary;

  /// No description provided for @cashRepayment.
  ///
  /// In ru, this message translates to:
  /// **'Возврат наличными'**
  String get cashRepayment;

  /// No description provided for @debtReducedNotificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Ваш долг уменьшен на {amount} ₸. ({note})'**
  String debtReducedNotificationBody(Object amount, Object note);

  /// No description provided for @reaidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Погашено: {amount} ₸'**
  String reaidAmount(Object amount);

  /// No description provided for @repayButton.
  ///
  /// In ru, this message translates to:
  /// **'Погасить'**
  String get repayButton;

  /// No description provided for @takenAmount.
  ///
  /// In ru, this message translates to:
  /// **'Взято'**
  String get takenAmount;

  /// No description provided for @repaidAmountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Погашено'**
  String get repaidAmountLabel;

  /// No description provided for @repayment.
  ///
  /// In ru, this message translates to:
  /// **'Погашение'**
  String get repayment;

  /// No description provided for @advance.
  ///
  /// In ru, this message translates to:
  /// **'Аванс'**
  String get advance;

  /// No description provided for @pendingStatus.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get pendingStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In ru, this message translates to:
  /// **'Отклонен'**
  String get rejectedStatus;

  /// No description provided for @repaidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Погашено: {amount} ₸'**
  String repaidAmount(Object amount);

  /// No description provided for @paymentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выплаты зарплат'**
  String get paymentsTitle;

  /// No description provided for @paymentTabToPay.
  ///
  /// In ru, this message translates to:
  /// **'К выплате'**
  String get paymentTabToPay;

  /// No description provided for @paymentTabPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают'**
  String get paymentTabPending;

  /// No description provided for @paymentTabHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get paymentTabHistory;

  /// No description provided for @paymentForWorker.
  ///
  /// In ru, this message translates to:
  /// **'Выплата: {name}'**
  String paymentForWorker(Object name);

  /// No description provided for @currentDebtWithPending.
  ///
  /// In ru, this message translates to:
  /// **'Текущий долг (с учетом ожидающих): {amount} ₸'**
  String currentDebtWithPending(Object amount);

  /// No description provided for @totalInDatabase.
  ///
  /// In ru, this message translates to:
  /// **'(Всего в базе: {amount} ₸)'**
  String totalInDatabase(Object amount);

  /// No description provided for @paymentAmountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сумма выплаты'**
  String get paymentAmountLabel;

  /// No description provided for @payButton.
  ///
  /// In ru, this message translates to:
  /// **'Выплатить'**
  String get payButton;

  /// No description provided for @paymentSentNotificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вам отправлена выплата'**
  String get paymentSentNotificationTitle;

  /// No description provided for @paymentSentNotificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите получение {amount} ₸'**
  String paymentSentNotificationBody(Object amount);

  /// No description provided for @paymentSentSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Выплата {amount} ₸ отправлена {name}. Ожидает подтверждения.'**
  String paymentSentSuccess(Object amount, Object name);

  /// No description provided for @pendingConfirmationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает подтв.: {amount} ₸'**
  String pendingConfirmationLabel(Object amount);

  /// No description provided for @unpaidWorkersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет работников к выплате'**
  String get unpaidWorkersTitle;

  /// No description provided for @pendingPaymentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет ожидающих выплат'**
  String get pendingPaymentsTitle;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет истории выплат'**
  String get paymentHistoryTitle;

  /// No description provided for @expensesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расходы'**
  String get expensesTitle;

  /// No description provided for @addExpense.
  ///
  /// In ru, this message translates to:
  /// **'Добавить расход'**
  String get addExpense;

  /// No description provided for @categoryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get categoryLabel;

  /// No description provided for @categoryProducts.
  ///
  /// In ru, this message translates to:
  /// **'Продукты'**
  String get categoryProducts;

  /// No description provided for @categoryTransport.
  ///
  /// In ru, this message translates to:
  /// **'Транспорт'**
  String get categoryTransport;

  /// No description provided for @categoryEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Оборудование'**
  String get categoryEquipment;

  /// No description provided for @categoryCommunal.
  ///
  /// In ru, this message translates to:
  /// **'Коммунальное'**
  String get categoryCommunal;

  /// No description provided for @categorySalary.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата/Аванс'**
  String get categorySalary;

  /// No description provided for @categoryOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get categoryOther;

  /// No description provided for @expenseAdded.
  ///
  /// In ru, this message translates to:
  /// **'Расход успешно добавлен!'**
  String get expenseAdded;

  /// No description provided for @totalForDay.
  ///
  /// In ru, this message translates to:
  /// **'Итого за день: {amount} ₸'**
  String totalForDay(Object amount);

  /// No description provided for @noExpensesToday.
  ///
  /// In ru, this message translates to:
  /// **'Нет расходов за этот день'**
  String get noExpensesToday;

  /// No description provided for @warehouseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get warehouseTitle;

  /// No description provided for @allIngredients.
  ///
  /// In ru, this message translates to:
  /// **'Все ингредиенты'**
  String get allIngredients;

  /// No description provided for @lowStock.
  ///
  /// In ru, this message translates to:
  /// **'Мало на складе'**
  String get lowStock;

  /// No description provided for @searchIngredients.
  ///
  /// In ru, this message translates to:
  /// **'Поиск ингредиентов...'**
  String get searchIngredients;

  /// No description provided for @addIngredient.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ингредиент'**
  String get addIngredient;

  /// No description provided for @editIngredient.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать ингредиент'**
  String get editIngredient;

  /// No description provided for @unitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ед. изм. (кг, л, шт)'**
  String get unitLabel;

  /// No description provided for @minStockLabel.
  ///
  /// In ru, this message translates to:
  /// **'Мин. остаток'**
  String get minStockLabel;

  /// No description provided for @updateStock.
  ///
  /// In ru, this message translates to:
  /// **'Обновить остаток'**
  String get updateStock;

  /// No description provided for @stockArrival.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get stockArrival;

  /// No description provided for @stockExpense.
  ///
  /// In ru, this message translates to:
  /// **'Расход'**
  String get stockExpense;

  /// No description provided for @unitPriceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цена за ед. изм.'**
  String get unitPriceLabel;

  /// No description provided for @transactionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Транзакции'**
  String get transactionsTitle;

  /// No description provided for @historyTitle.
  ///
  /// In ru, this message translates to:
  /// **'История операций'**
  String get historyTitle;

  /// No description provided for @noIngredientsFound.
  ///
  /// In ru, this message translates to:
  /// **'Ингредиенты не найдены'**
  String get noIngredientsFound;

  /// No description provided for @ingredientSaved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено!'**
  String get ingredientSaved;

  /// No description provided for @nameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get nameLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get quantityLabel;

  /// No description provided for @noteLabel.
  ///
  /// In ru, this message translates to:
  /// **'Примечание'**
  String get noteLabel;

  /// No description provided for @writeOff.
  ///
  /// In ru, this message translates to:
  /// **'Списать'**
  String get writeOff;

  /// No description provided for @inventory.
  ///
  /// In ru, this message translates to:
  /// **'Остатки'**
  String get inventory;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @totalExpenses.
  ///
  /// In ru, this message translates to:
  /// **'Всего расходов'**
  String get totalExpenses;

  /// No description provided for @generalQrTitle.
  ///
  /// In ru, this message translates to:
  /// **'Общий QR-код'**
  String get generalQrTitle;

  /// No description provided for @qrPrintHint.
  ///
  /// In ru, this message translates to:
  /// **'Распечатайте этот QR-код и повесьте на кухне. Работники будут сканировать его при приходе и уходе.'**
  String get qrPrintHint;

  /// No description provided for @qrForCheckIn.
  ///
  /// In ru, this message translates to:
  /// **'QR-код для отметки'**
  String get qrForCheckIn;

  /// No description provided for @scanForCheckInOut.
  ///
  /// In ru, this message translates to:
  /// **'Сканируйте для прихода и ухода'**
  String get scanForCheckInOut;

  /// No description provided for @manualCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код для ручного ввода'**
  String get manualCodeLabel;

  /// No description provided for @workerInstructionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Инструкция для работников'**
  String get workerInstructionTitle;

  /// No description provided for @workerStep1.
  ///
  /// In ru, this message translates to:
  /// **'1. Откройте приложение Ailin Tattileri'**
  String get workerStep1;

  /// No description provided for @workerStep2.
  ///
  /// In ru, this message translates to:
  /// **'2. Нажмите \'Сканировать QR\' на главном экране'**
  String get workerStep2;

  /// No description provided for @workerStep3.
  ///
  /// In ru, this message translates to:
  /// **'3. Наведите камеру на этот код'**
  String get workerStep3;

  /// No description provided for @analyticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get analyticsTitle;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get thisMonth;

  /// No description provided for @pickPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать период'**
  String get pickPeriod;

  /// No description provided for @revenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get revenue;

  /// No description provided for @ordersCount.
  ///
  /// In ru, this message translates to:
  /// **'Заказов'**
  String get ordersCount;

  /// No description provided for @totalExpensesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Расходы'**
  String get totalExpensesLabel;

  /// No description provided for @netProfit.
  ///
  /// In ru, this message translates to:
  /// **'Чистая прибыль'**
  String get netProfit;

  /// No description provided for @revenueDynamics.
  ///
  /// In ru, this message translates to:
  /// **'Динамика выручки'**
  String get revenueDynamics;

  /// No description provided for @topProducts.
  ///
  /// In ru, this message translates to:
  /// **'Топ товаров'**
  String get topProducts;

  /// No description provided for @byPopularity.
  ///
  /// In ru, this message translates to:
  /// **'по популярности'**
  String get byPopularity;

  /// No description provided for @ordersLabel.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get ordersLabel;

  /// No description provided for @quantityShort.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get quantityShort;

  /// No description provided for @noData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get noData;

  /// No description provided for @finance.
  ///
  /// In ru, this message translates to:
  /// **'Финансы'**
  String get finance;

  /// No description provided for @totalSalariesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Зарплаты'**
  String get totalSalariesLabel;

  /// No description provided for @averageCheck.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get averageCheck;

  /// No description provided for @noDataForPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных за этот период'**
  String get noDataForPeriod;

  /// No description provided for @workerDashboardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моя смена'**
  String get workerDashboardTitle;

  /// No description provided for @loginRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в систему'**
  String get loginRequired;

  /// No description provided for @notRegisteredAsWorker.
  ///
  /// In ru, this message translates to:
  /// **'Вы не зарегистрированы как работник'**
  String get notRegisteredAsWorker;

  /// No description provided for @scanQr.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR'**
  String get scanQr;

  /// No description provided for @checkInTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Время прихода'**
  String get checkInTimeLabel;

  /// No description provided for @checkOutTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Время ухода'**
  String get checkOutTimeLabel;

  /// No description provided for @hoursWorkedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Отработано часов'**
  String get hoursWorkedLabel;

  /// No description provided for @earned.
  ///
  /// In ru, this message translates to:
  /// **'Заработано'**
  String get earned;

  /// No description provided for @advanceRepayment.
  ///
  /// In ru, this message translates to:
  /// **'Погашение аванса'**
  String get advanceRepayment;

  /// No description provided for @totalToPay.
  ///
  /// In ru, this message translates to:
  /// **'Итого к выдаче'**
  String get totalToPay;

  /// No description provided for @total.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get total;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get ok;

  /// No description provided for @scanForCheckIn.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте для начала смены'**
  String get scanForCheckIn;

  /// No description provided for @scanForCheckOut.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте для завершения смены'**
  String get scanForCheckOut;

  /// No description provided for @shiftCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Смена завершена'**
  String get shiftCompleted;

  /// No description provided for @myAdvances.
  ///
  /// In ru, this message translates to:
  /// **'Мои Авансы'**
  String get myAdvances;

  /// No description provided for @currentDebt.
  ///
  /// In ru, this message translates to:
  /// **'Текущий долг'**
  String get currentDebt;

  /// No description provided for @debtRepayment.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долга'**
  String get debtRepayment;

  /// No description provided for @pending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get rejected;

  /// No description provided for @reject.
  ///
  /// In ru, this message translates to:
  /// **'Отказаться'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get accept;

  /// No description provided for @advanceAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Аванс принят ✅'**
  String get advanceAccepted;

  /// No description provided for @advanceRejected.
  ///
  /// In ru, this message translates to:
  /// **'Аванс отклонен 🚫'**
  String get advanceRejected;

  /// No description provided for @salaryHistory.
  ///
  /// In ru, this message translates to:
  /// **'История зарплат'**
  String get salaryHistory;

  /// No description provided for @noWorkerData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных о работнике'**
  String get noWorkerData;

  /// No description provided for @historyEmpty.
  ///
  /// In ru, this message translates to:
  /// **'История пуста'**
  String get historyEmpty;

  /// No description provided for @noSalariesYet.
  ///
  /// In ru, this message translates to:
  /// **'Зарплат пока нет'**
  String get noSalariesYet;

  /// No description provided for @hoursWorkedShort.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч. работы'**
  String hoursWorkedShort(Object hours);

  /// No description provided for @deducted.
  ///
  /// In ru, this message translates to:
  /// **'Удержано'**
  String get deducted;

  /// No description provided for @outOf.
  ///
  /// In ru, this message translates to:
  /// **'из {total}'**
  String outOf(Object total);

  /// No description provided for @invalidQrCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный QR-код. Используйте общий QR-код кухни.'**
  String get invalidQrCode;

  /// No description provided for @alreadyCheckedOut.
  ///
  /// In ru, this message translates to:
  /// **'Вы уже отметили уход сегодня'**
  String get alreadyCheckedOut;

  /// No description provided for @checkInMarked.
  ///
  /// In ru, this message translates to:
  /// **'✓ Приход отмечен'**
  String get checkInMarked;

  /// No description provided for @checkOutMarked.
  ///
  /// In ru, this message translates to:
  /// **'✓ Уход отмечен'**
  String get checkOutMarked;

  /// No description provided for @attendanceCheckInTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приход на смену 🟢'**
  String get attendanceCheckInTitle;

  /// No description provided for @attendanceCheckOutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Завершение смены 🏁'**
  String get attendanceCheckOutTitle;

  /// No description provided for @beganWork.
  ///
  /// In ru, this message translates to:
  /// **'{name} начал работу в {time}'**
  String beganWork(Object name, Object time);

  /// No description provided for @finishedWork.
  ///
  /// In ru, this message translates to:
  /// **'{name} завершил работу. Отработано: {hours} ч'**
  String finishedWork(Object hours, Object name);

  /// No description provided for @scanQrInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на общий QR-код'**
  String get scanQrInstruction;

  /// No description provided for @repayments.
  ///
  /// In ru, this message translates to:
  /// **'Погашения'**
  String get repayments;

  /// No description provided for @pendingAdvances.
  ///
  /// In ru, this message translates to:
  /// **'Ожидающие авансы'**
  String get pendingAdvances;

  /// No description provided for @advanceHistory.
  ///
  /// In ru, this message translates to:
  /// **'История авансов'**
  String get advanceHistory;

  /// No description provided for @noAdvancesOrRepayments.
  ///
  /// In ru, this message translates to:
  /// **'Авансов или погашений пока нет'**
  String get noAdvancesOrRepayments;

  /// No description provided for @paymentHistory.
  ///
  /// In ru, this message translates to:
  /// **'История выплат'**
  String get paymentHistory;

  /// No description provided for @currentBalance.
  ///
  /// In ru, this message translates to:
  /// **'Текущий баланс (Невыплачено)'**
  String get currentBalance;

  /// No description provided for @operationHistory.
  ///
  /// In ru, this message translates to:
  /// **'История операций'**
  String get operationHistory;

  /// No description provided for @paymentHistoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'История выплат пуста'**
  String get paymentHistoryEmpty;

  /// No description provided for @paymentConfirmedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо! Получение подтверждено.'**
  String get paymentConfirmedSuccess;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @confirmReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить получение'**
  String get confirmReceipt;

  /// No description provided for @orderPlaced.
  ///
  /// In ru, this message translates to:
  /// **'Заказ оформлен!'**
  String get orderPlaced;

  /// No description provided for @orderPaymentUponPickup.
  ///
  /// In ru, this message translates to:
  /// **'Оплата производится при получении заказа в точке самовывоза'**
  String get orderPaymentUponPickup;

  /// No description provided for @orderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер заказа'**
  String get orderNumber;

  /// No description provided for @orderStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get orderStatus;

  /// No description provided for @orderStatusAwaitingPayment.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает оплаты'**
  String get orderStatusAwaitingPayment;

  /// No description provided for @deliveryType.
  ///
  /// In ru, this message translates to:
  /// **'Тип доставки'**
  String get deliveryType;

  /// No description provided for @pickup.
  ///
  /// In ru, this message translates to:
  /// **'Самовывоз'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get delivery;

  /// No description provided for @pickupPoint.
  ///
  /// In ru, this message translates to:
  /// **'Точка самовывоза'**
  String get pickupPoint;

  /// No description provided for @deliveryAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get deliveryAddress;

  /// No description provided for @readiness.
  ///
  /// In ru, this message translates to:
  /// **'Готовность'**
  String get readiness;

  /// No description provided for @deliveryTime.
  ///
  /// In ru, this message translates to:
  /// **'Время доставки'**
  String get deliveryTime;

  /// No description provided for @totalAmount.
  ///
  /// In ru, this message translates to:
  /// **'Итоговая сумма'**
  String get totalAmount;

  /// No description provided for @goToMyOrders.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к моим заказам'**
  String get goToMyOrders;

  /// No description provided for @returnToMain.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться на главную'**
  String get returnToMain;
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
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
