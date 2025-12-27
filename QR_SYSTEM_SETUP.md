# ✅ Система QR-кодов для работников - ГОТОВА!

## 🎯 Как это работает:

### **Для админа:**

1. **Открой "Работники"** → нажми кнопку QR-кода (📱) в AppBar
2. **Увидишь общий QR-код** с текстом "KITCHEN_CHECKIN"
3. **Распечатай и повесь** на кухне
4. **Создай работников:**
   - Имя: Асан
   - Телефон: +7 777 123 4567
   - Email: asan@work.kz (для входа)
   - Должность: Повар
   - Ставка: 500 ₸/час

### **Для работника:**

1. **Зарегистрируйся** с email (который указал админ)
2. **Роль должна быть "worker"** (админ устанавливает в Firestore)
3. **Войди в приложение** → увидишь "Моя смена"
4. **При приходе:**
   - Нажми "Сканировать QR"
   - Отсканируй общий QR-код
   - ✅ Приход отмечен: 09:00
5. **При уходе:**
   - Снова отсканируй тот же QR-код
   - ✅ Уход отмечен: 18:00, Отработано: 9.0 ч

---

## 📝 Что нужно сделать вручную:

### Шаг 1: Добавить маршрут в main.dart

Открой `lib/main.dart` и добавь импорт после строки ~18:
```dart
import 'package:ailin_tattileri_app/features/worker/qr_scanner/qr_scanner_screen.dart';
```

Затем добавь маршрут перед закрывающей скобкой `]` (перед строкой ~95):
```dart
    GoRoute(
      path: '/worker/qr-scanner',
      builder: (context, state) => const QRScannerScreen(),
    ),
```

### Шаг 2: Настроить роли в Firestore

Для работника в коллекции `users`:
```json
{
  "email": "asan@work.kz",
  "name": "Асан",
  "role": "worker",
  "createdAt": "timestamp"
}
```

Для админа в коллекции `users`:
```json
{
  "email": "admin@example.com",
  "name": "Админ",
  "role": "admin",
  "createdAt": "timestamp"
}
```

### Шаг 3: Связать работника с пользователем

Когда админ создаёт работника, нужно указать `userId`.

В `WorkersScreen`, метод `_showAddWorkerDialog` (строка ~180), найди где создаётся `Worker`:

```dart
final worker = Worker(
  id: '',
  name: nameController.text.trim(),
  position: positionController.text.trim(),
  phone: phoneController.text.trim(),
  hourlyRate: double.tryParse(hourlyRateController.text) ?? 0,
  userId: null, // ⚠️ НУЖНО ДОБАВИТЬ ЛОГИКУ
  createdAt: DateTime.now(),
);
```

**Вариант 1 (простой):** Админ вручную вводит `userId` работника

**Вариант 2 (автоматический):** Добавь поле email и найди пользователя:
```dart
final emailController = TextEditingController();

// В диалоге добавь:
TextField(
  controller: emailController,
  decoration: const InputDecoration(
    labelText: "Email работника",
    border: OutlineInputBorder(),
  ),
  keyboardType: TextInputType.emailAddress,
),

// При создании:
String? userId;
if (emailController.text.trim().isNotEmpty) {
  final usersQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: emailController.text.trim())
      .limit(1)
      .get();
  
  if (usersQuery.docs.isNotEmpty) {
    userId = usersQuery.docs.first.id;
  }
}

final worker = Worker(
  // ...
  userId: userId,
  // ...
);
```

### Шаг 4: Разрешения камеры (Android)

Добавь в `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## 🎉 Готово!

После выполнения этих шагов:

1. ✅ Админ видит кнопку QR в "Работники"
2. ✅ Админ может показать общий QR-код
3. ✅ Работник сканирует QR при приходе
4. ✅ Работник сканирует QR при уходе
5. ✅ Админ видит время прихода/ухода и часы
6. ✅ Админ вводит зарплату вручную

---

## 🔍 Как проверить:

1. Создай пользователя с ролью "worker"
2. Создай работника в админке (укажи userId)
3. Войди как работник
4. Открой "Моя смена"
5. Нажми "Сканировать QR"
6. Отсканируй QR-код из админки
7. Проверь, что время записалось

---

## 📱 Экраны:

- ✅ `GenerateQRScreen` - показ общего QR-кода (для админа)
- ✅ `WorkerDashboardScreen` - моя смена (для работника)
- ✅ `QRScannerScreen` - сканер QR (для работника)
- ✅ `WorkersScreen` - список работников (для админа)
- ✅ `WorkerDetailsScreen` - детали работника (для админа)

Всё готово! 🚀
