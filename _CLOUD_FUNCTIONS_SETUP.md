# Настройка Push-уведомлений (Cloud Functions)

Чтобы уведомления приходили на телефон, даже когда приложение закрыто, необходимо развернуть Firebase Cloud Function.

## Шаг 1: Подготовка окружения
Убедитесь, что у вас установлен **Node.js** и **Firebase CLI**.
В терминале:
```bash
npm install -g firebase-tools
firebase login
```

## Шаг 2: Инициализация функций
Перейдите в корень проекта `ailin_tattileri_app` (или на уровень выше, где удобно иметь папку functions).
```bash
firebase init functions
```
1. Выберите опцию **Use an existing project**.
2. Выберите ваш проект Firebase.
3. Язык: **JavaScript**.
4. ESLint: **No**.
5. Install dependencies: **Yes**.

## Шаг 3: Код функции
Откройте созданный файл `functions/index.js` и замените его содержимое на следующий код:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const receiverId = data.receiverId; // Worker ID or 'admin'

    if (!receiverId) {
      console.log("No receiverId found");
      return;
    }

    let targetTokens = [];

    if (receiverId === 'admin') {
      // Send to all users with role 'admin' (if you implement roles in users collection)
      // OR send to a topic.
      // For now, let's log skipping admin implementation if no topic subscription setup
      console.log("Admin notification - skipping specifics for now");
      return;
    } else {
      // Logic for Worker
      // 1. Check if receiverId is a Worker ID (Firestore ID)
      const workerDoc = await admin.firestore().collection('workers').doc(receiverId).get();
      
      let userId = receiverId; // Assume it might be userId directly
      if (workerDoc.exists && workerDoc.data().userId) {
        userId = workerDoc.data().userId; // Get the linked Auth ID
      }

      // 2. Get User Doc to find FCM Token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists || !userDoc.data().fcmToken) {
        console.log("No FCM token found for user:", userId);
        return;
      }

      targetTokens.push(userDoc.data().fcmToken);
    }

    if (targetTokens.length === 0) return;

    // Send messages
    const validTokens = targetTokens.filter(t => t);
    
    if (validTokens.length > 0) {
        const message = {
            notification: {
                title: data.title,
                body: data.body,
            },
            tokens: validTokens, // Multicast
            android: {
                priority: "high",
                notification: {
                  channelId: "high_importance_channel" 
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default"
                    }
                }
            }
        };

        try {
            const response = await admin.messaging().sendMulticast(message);
            console.log("Successfully sent message:", response.successCount);
            if (response.failureCount > 0) {
               response.responses.forEach((resp, idx) => {
                   if (!resp.success) {
                       console.error("Error sending to token:", validTokens[idx], resp.error);
                   }
               });
            }
        } catch (error) {
            console.log("Error sending message:", error);
        }
    }
  });
```

## Шаг 4: Деплой
В терминале (в папке `functions` или корне, где был init):
```bash
firebase deploy --only functions
```

**Важно:** Для работы внешних функций (отправка в FCM) ваш проект Firebase должен быть на тарифе **Blaze** (Pay as you go). Он имеет щедрый бесплатный лимит, но карта необходима.
