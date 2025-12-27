# Premium Design System

Система переиспользуемых компонентов для единообразного премиального дизайна приложения.

## 📦 Компоненты

### 1. PremiumCard (`lib/core/widgets/premium_card.dart`)

Базовая карточка с тенями и закругленными углами.

```dart
import 'package:ailin_tattileri_app/core/widgets/premium_card.dart';

// Простая карточка
PremiumCard(
  child: Text('Контент'),
)

// Кликабельная карточка
PremiumCard(
  onTap: () => print('Нажато'),
  child: Text('Кликни меня'),
)

// Кастомная карточка
PremiumCard(
  padding: EdgeInsets.all(16),
  borderRadius: 12,
  color: Colors.blue.withOpacity(0.1),
  child: Text('Кастомная'),
)
```

### 2. PremiumStatCard (`lib/core/widgets/premium_card.dart`)

Карточка для отображения статистики.

```dart
PremiumStatCard(
  title: "Новые заказы",
  value: "42",
  icon: Icons.shopping_bag,
  color: Colors.blue,
  onTap: () => navigateToOrders(),
)
```

### 3. PremiumInfoCard (`lib/core/widgets/premium_card.dart`)

Информационная карточка с иконкой и текстом.

```dart
PremiumInfoCard(
  title: "Настройки",
  subtitle: "Управление приложением",
  icon: Icons.settings,
  iconColor: Colors.purple,
  onTap: () => openSettings(),
)
```

### 4. PremiumButton (`lib/core/widgets/premium_button.dart`)

Стилизованная кнопка.

```dart
// Обычная кнопка
PremiumButton(
  text: "Сохранить",
  onPressed: () => save(),
)

// С иконкой
PremiumButton(
  text: "Добавить",
  icon: Icons.add,
  onPressed: () => add(),
)

// Outlined стиль
PremiumButton(
  text: "Отмена",
  isOutlined: true,
  onPressed: () => cancel(),
)

// С загрузкой
PremiumButton(
  text: "Загрузка...",
  isLoading: true,
)
```

### 5. PremiumSmallButton (`lib/core/widgets/premium_button.dart`)

Компактная кнопка для небольших пространств.

```dart
PremiumSmallButton(
  text: "Фильтр",
  icon: Icons.filter_list,
  onPressed: () => showFilter(),
)
```

## 🎨 Стили

### Текстовые стили (`lib/core/theme/premium_styles.dart`)

```dart
import 'package:ailin_tattileri_app/core/theme/premium_styles.dart';

// Заголовки
Text('Заголовок 1', style: PremiumTextStyles.h1)
Text('Заголовок 2', style: PremiumTextStyles.h2)
Text('Заголовок 3', style: PremiumTextStyles.h3)
Text('Заголовок 4', style: PremiumTextStyles.h4)

// Основной текст
Text('Большой текст', style: PremiumTextStyles.bodyLarge)
Text('Средний текст', style: PremiumTextStyles.bodyMedium)
Text('Маленький текст', style: PremiumTextStyles.bodySmall)

// Метки
Text('Метка', style: PremiumTextStyles.label)
Text('Жирная метка', style: PremiumTextStyles.labelBold)

// Специальные
Text('Подпись', style: PremiumTextStyles.caption)
Text('OVERLINE', style: PremiumTextStyles.overline)
```

### Цвета (`lib/core/theme/premium_styles.dart`)

```dart
import 'package:ailin_tattileri_app/core/theme/premium_styles.dart';

// Оттенки серого
PremiumColors.gray50  // Самый светлый
PremiumColors.gray100
PremiumColors.gray200
...
PremiumColors.gray900 // Самый темный

// Статусные цвета
PremiumColors.success  // Зеленый
PremiumColors.warning  // Оранжевый
PremiumColors.error    // Красный
PremiumColors.info     // Синий

// Фоны
PremiumColors.background // Фон приложения
PremiumColors.surface    // Фон карточек
```

## ✅ Обновленные экраны

- ✅ **AdminDashboardScreen** - использует PremiumStatCard
- ✅ **AnalyticsScreen** - премиальный дизайн с графиками

## 🚀 Как использовать

1. Импортируйте нужные компоненты:
```dart
import 'package:ailin_tattileri_app/core/widgets/premium_card.dart';
import 'package:ailin_tattileri_app/core/widgets/premium_button.dart';
import 'package:ailin_tattileri_app/core/theme/premium_styles.dart';
```

2. Используйте вместо стандартных виджетов:
   - `Container` → `PremiumCard`
   - `ElevatedButton` → `PremiumButton`
   - `TextStyle(...)` → `PremiumTextStyles.h1`

3. Следуйте единому стилю:
   - Отступы: 16, 20, 24
   - Радиусы: 12, 16, 20, 24
   - Тени: `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: Offset(0, 8))`

## 📝 Примеры

### Создание экрана со статистикой

```dart
class MyStatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: AppBar(
        title: Text('Статистика', style: PremiumTextStyles.h3),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PremiumStatCard(
                    title: "Продажи",
                    value: "1,234",
                    icon: Icons.trending_up,
                    color: PremiumColors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: PremiumStatCard(
                    title: "Заказы",
                    value: "56",
                    icon: Icons.shopping_cart,
                    color: PremiumColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎯 Следующие шаги

Для обновления других экранов:
1. Замените `Container` на `PremiumCard`
2. Замените кнопки на `PremiumButton`
3. Используйте `PremiumTextStyles` для текста
4. Используйте `PremiumColors` для цветов
5. Следуйте spacing guidelines (16, 20, 24)
