import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final text = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text.notificationsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              tooltip: text.readAll,
              onPressed: () {
                NotificationService().markAllAsRead(currentUser.uid);
              },
            ),
        ],
      ),
      body: currentUser == null
          ? _buildAuthError(context, text)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('receiverId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("${text.loadingError}: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context, text);
                }

                final notifications = snapshot.data!.docs;
                // Client-side sorting to fix missing Index error
                notifications.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final Timestamp? timeA = dataA['createdAt'];
                  final Timestamp? timeB = dataB['createdAt'];
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  return timeB.compareTo(timeA);
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _NotificationCard(id: doc.id, data: data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildAuthError(BuildContext context, AppLocalizations text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Text(
            text.notificationsLoginRequired,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text.notificationsEmpty,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Text(
            text.notificationsInfo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _NotificationCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isRead = data['isRead'] ?? false;
    final Timestamp? timestamp = data['createdAt'];
    final DateTime? date = timestamp?.toDate();
    final String timeStr = date != null
        ? DateFormat('dd MMM, HH:mm').format(date)
        : '';

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          NotificationService().markAsRead(id);
        }
        // Optional: Navigate to order details if type matches
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isRead
              ? Border.all(color: theme.dividerColor.withOpacity(0.1))
              : Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withOpacity(0.03)
                  : AppColors.primary.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRead
                    ? theme.scaffoldBackgroundColor
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconForType(data['type']),
                color: isRead ? Colors.grey[400] : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getLocalizedTitle(data, text) ??
                              data['title'] ??
                              text.notificationsTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: isRead
                                ? theme.textTheme.bodyLarge?.color?.withOpacity(
                                    0.7,
                                  )
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getLocalizedBody(data, text) ?? data['body'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ??
                          Colors.grey[400],
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          theme.textTheme.bodySmall?.color?.withOpacity(0.5) ??
                          Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications_rounded;
    switch (type.toLowerCase()) {
      case 'order_status':
      case 'order_status_update':
      case 'new_order':
        return Icons.local_shipping_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'attendance_checkin':
        return Icons.login_rounded;
      case 'attendance_checkout':
        return Icons.logout_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  String? _getLocalizedTitle(Map<String, dynamic> data, AppLocalizations text) {
    final type = data['type'] as String?;
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'order_status':
      case 'order_status_update':
        return text.notificationTypeOrder;
      case 'new_order':
        return text.notificationTitleNewOrder;
      case 'promo':
        return text.notificationTypePromo;
      case 'security':
        return text.notificationTypeSecurity;
      case 'payment':
        return text.notificationTypePayment;
      case 'attendance_checkin':
        return text.notificationTypeAttendanceCheckIn;
      case 'attendance_checkout':
        return text.notificationTypeAttendanceCheckOut;
      default:
        return null;
    }
  }

  String? _getLocalizedBody(Map<String, dynamic> data, AppLocalizations text) {
    final type = data['type'] as String?;
    final status = data['status'] as String?;
    final body = data['body'] as String?;

    // 1. Try to use status code (Backend-driven)
    if (type == 'order_status_update' && status != null) {
      switch (status) {
        case 'processing':
          return text.orderStatusProcessingMessage;
        case 'ready':
          return text.orderStatusReadyMessage;
        case 'completed':
          return text.orderStatusCompletedMessage;
        case 'cancelled':
          return text.orderStatusCancelledMessage;
        default:
          return text.orderStatusDefaultMessage;
      }
    }

    // 2. Fallback: Match legacy Russian text (Client-side fix)
    if (body != null) {
      if (body.contains('Заказ выполнен'))
        return text.orderStatusCompletedMessage;
      if (body.contains('Ваш заказ отменён'))
        return text.orderStatusCancelledMessage;
      if (body.contains('Статус заказа изменён'))
        return text.orderStatusDefaultMessage;
      if (body.contains('принят в обработку'))
        return text.orderStatusProcessingMessage;
      if (body.contains('готов к выдаче')) return text.orderStatusReadyMessage;
    }

    if (type == 'new_order' && data['amount'] != null) {
      return text.notificationBodyNewOrder(data['amount']);
    }

    return null;
  }
}
