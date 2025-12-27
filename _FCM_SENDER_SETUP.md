# Настройка отправки уведомлений (Без тарифа Blaze)

Поскольку тариф Blaze недоступен, мы будем отправлять уведомления напрямую из приложения администратора, используя сервисный аккаунт Firebase.

## Шаг 1: Получение ключа доступа
1. Перейдите в [Firebase Console](https://console.firebase.google.com/).
2. Откройте ваш проект `cake-app-ailin`.
3. Нажмите на шестеренку ⚙️ (Настройки проекта) -> **Project settings**.
4. Перейдите на вкладку **Service accounts**.
5. Прокрутите вниз и нажмите кнопку **Generate new private key**.
6. Соцподтвердите действие ("Generate key").
7. На ваш компьютер скачается JSON-файл (например, `cake-app-ailin-firebase-adminsdk-xxxxx.json`).

## Шаг 2: Вставка ключа в приложение
1. Откройте этот файл с помощью Блокнота или любого текстового редактора.
2. Скопируйте **весь текст целиком**.
3. Вернитесь в VS Code.
4. Откройте файл:
   `lib/core/services/fcm_sender_service.dart`
5. Найдите там переменную `_serviceAccountJson`.
6. Замените шаблонный текст внутри тройных кавычек `''' ... '''` на скопированный вами JSON.

Пример, как должно выглядеть:
```dart
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "cake-app-ailin",
  "private_key_id": "a1b2c3d4...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgk...",
  "client_email": "firebase-adminsdk-xxxx@cake-app-ailin.iam.gserviceaccount.com",
  "client_id": "123456789...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
  ''';
```

## Шаг 3: Сохранение и запуск
Сохраните файл `fcm_sender_service.dart` и перезапустите приложение.
Теперь, когда вы будете выдавать аванс, уведомления будут приходить на телефоны работников, даже если приложение свернуто.

**Примечание:** Этот метод хранит секретный ключ внутри приложения. Для внутреннего использования в вашем бизнесе это нормально. Но если вы захотите выложить приложение в Play Market для всей страны, этот ключ нужно будет убрать на сервер.
