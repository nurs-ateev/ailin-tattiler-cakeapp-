import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class FCMSenderService {
  // ---------------------------------------------------------------------------
  // ВСТАВЬТЕ СЮДА СОДЕРЖИМОЕ ВАШЕГО SERVICE-ACCOUNT.JSON
  // Это НЕБЕЗОПАСНО для публичных приложений, но допустимо для внутреннего использования.
  // Скопируйте содержимое файла полностью внутрь кавычек (используйте ''' для многострочности).
  // ---------------------------------------------------------------------------
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "cake-app-ailin",
  "private_key_id": "0c08e010ab3ee63f350a6ddc1ba86cdc28e77677",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCMObE3awIoC99v\\nXHeVxZMLBXIC9FR4odJ8ee/B1gKzvKQ33iD8gtbIb3A0Ns+0nRip04gTQFFtZjeU\\njUh80NG8n6j+oZFbjswwLXeC0SVuBhto6OTc+bOLl5ZqDEOIgaLihJ1TW3zb5H2T\\n+XnVqoJiRJNWbGtZ62kY+IBsbBYwttgsPNb2/grsN1SH/GOGn9DQY0T4wg/CjjBf\\n3E27+mtOLA0kCgTI9DHXmLXNzpDsOO+QCNPo+EJ+g4f3re7oZqh4y51kAVXUu3EU\\nFiv7ZZoVGWQFTd+lM5uNf2MNg0sdQFmOtayrvuhxajvjxrwwDnt3pUr4qTlb54ax\\nhjbV07/NAgMBAAECggEACpQbSdxoBig3zobPMQyTFlNZFvQilOjVAFXSRVEqlNol\\nQ7Sy0DHjrQJ2gxiOd1LxpnWCOrzmV7E3fgdhjE7+6kgGNP1wgekmKiKdSpBneTh7\\nOWEhIN2H6BRDFpQpxRgjNwunnb9VY6EGFejNwkAnLsLQdbDfXAzTJH0yHQZ+GbsY\\n6CHQYzVk5SSjRAF2uVCfZU/Sb2IaXAxl9KLiRdz/LRpq4g4Tc9wtvL/mUGvlEd1d\\nXIfzA/VfKwi8FV83U3XPqoqQoaeHneGD8xunP0Fpjny2vB5c/0L3iM2IdP7fLUjl\\nrPbO6Mgt4uN1M6s+dH/TimNfwVgaoBRqutkTc7KbmQKBgQDERwaRc3PdfxJuryKu\\nd/dEpTR9UqXpWVcGjd3o2SBqyx22RZcRZIUEZvbO060vnXG6EF1kPm464IvabrvH\\neFV/IHTDqh3kAKuMdcw8qQ7sDpd8aYYc/JtDgFYyqeOE9blh4qTWYyQBUtG/V6C4\\nUW+zJIp3QKVpGqWkxpflMPTUJQKBgQC25IGATbAZqX2tgiJul9VY2s5YiaJCGKjo\\np5CVgtonwVq0ncmooYf2MOyU5RscaS8/Tr+N5IUy+VUV5PnvwewxfrZ8cYO5w0L1\\n1TDcFgvrqSCNiw8peyOmGUPb6hlRA3AMdKZqgmujF10AKcwGewEb4FURFTzI9R5N\\niQ+xN+PYiQKBgHZeKwzepnpmntQXVIAJIxrH0q7df+cJFN2EAtbg0pb05Xc94ov/\\npeRwv9kdeO0lMye1pMzGha2GK3FQpHf4Dv96sFArsJkG+m3bwI64maIsbpj9/n5O\\nrMf5hoJJSEev9NueVjBgW59ctdeB3hAqNIXBvKuMVfTbuBd2GLaEXrHtAoGANDo+\\nzP/iaQGgtRqzcHeFYlFhmaD8J/nYyk+Hl1p9p9qsZ2Wjv7cZF3HTLZXbTxqudlqr\\nkv6OFwdih9USlqf/Jgc0X4cfAb5D8eXGhSL6lnp+pEzwsHzMqlMOsM9CGYNszPHG\\n0CWcTT+PvEszSyp3H5nJUQ6KhCyTUbrxMz9tnlkCgYEAgN/aUDkoFXMtlf50BUso\\njWy7mw1VBMIsJZClSyLGPQ/Qs45MOeFsPtjpDH0/+/L+w0qx56YzWUHJRFshISoz\\nTVH/sHsnkFGagUrkHov64ncgC9xNPBo30wffDxtxnvZgeuQ8oZVdliT2KDGVpIPl\\nRZZ2MyTrn4qdWcwCVsABLVc=\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@cake-app-ailin.iam.gserviceaccount.com",
  "client_id": "101694446006302247959",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40cake-app-ailin.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
  ''';
  // ---------------------------------------------------------------------------

  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(
        _serviceAccountJson,
      );
      final client = await clientViaServiceAccount(credentials, _scopes);

      // Get Project ID dynamically from the JSON
      final Map<String, dynamic> jsonMap = jsonDecode(_serviceAccountJson);
      final String projectId = jsonMap['project_id'];

      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'data': data, // Custom data
            'android': {
              'priority': 'high',
              'notification': {
                'channelId':
                    'high_importance_channel', // Must match Android Channel ID
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default'},
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('FCM Notification sent successfully: ${response.body}');
      } else {
        print(
          'Error sending FCM Notification: ${response.statusCode} ${response.body}',
        );
      }

      client.close();
    } catch (e) {
      print('Error in FCMSenderService: $e');
    }
  }
}
