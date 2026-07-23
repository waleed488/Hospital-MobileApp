import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return Icons.event_available;
      case 'cancelled':
        return Icons.event_busy;
      case 'declined':
      case 'rejected':
        return Icons.error_outline;
      case 'prescription':
        return Icons.medication;
      case 'lab':
        return Icons.science_outlined;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.notifications_active;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'declined':
      case 'rejected':
        return AppColors.error;
      case 'prescription':
        return Colors.orange;
      case 'lab':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firestoreService.getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const EmptyState(
              title: "All Caught Up!",
              message: "No new notifications yet. We'll alert you when anything updates.",
              icon: Icons.notifications_off_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notif = list[index];
              final notifColor = _getColorForType(notif.type);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: notif.isRead ? 0 : 2,
                color: notif.isRead ? Colors.white.withOpacity(0.85) : Colors.white,
                shadowColor: Colors.black.withOpacity(0.04),
                child: InkWell(
                  onTap: () async {
                    if (!notif.isRead) {
                      await _firestoreService.markNotificationAsRead(notif.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: notifColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notif.type),
                            color: notifColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: notif.isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: notif.isRead
                                            ? Colors.grey.shade600
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      height: 8,
                                      width: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: notif.isRead
                                      ? Colors.grey.shade500
                                      : AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _formatTime(notif.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () async {
                            try {
                              await _firestoreService.deleteNotification(notif.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Notification Deleted")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to delete: $e")),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }
}
