import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_model.dart';
import '../../features/notifications/providers/notifications_provider.dart';

class InAppNotificationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const InAppNotificationWrapper({super.key, required this.child});

  @override
  ConsumerState<InAppNotificationWrapper> createState() => _InAppNotificationWrapperState();
}

class _InAppNotificationWrapperState extends ConsumerState<InAppNotificationWrapper>
    with SingleTickerProviderStateMixin {
  final Set<String> _seenNotifIds = {};
  bool _isInitialLoad = true;
  NotificationModel? _currentNotif;
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _showNotification(NotificationModel notif) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotif = notif;
    });

    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(seconds: 6), () {
      _dismissNotification();
    });
  }

  void _dismissNotification() {
    _dismissTimer?.cancel();
    if (mounted) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentNotif = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for live new notifications
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsListProvider, (prev, next) {
      final list = next.valueOrNull ?? [];
      if (list.isEmpty) return;

      if (_isInitialLoad) {
        // Record existing IDs without triggering pop-up on first app open
        for (final n in list) {
          _seenNotifIds.add(n.id);
        }
        _isInitialLoad = false;
        return;
      }

      // Check for genuinely new incoming notifications
      for (final n in list) {
        if (!_seenNotifIds.contains(n.id)) {
          _seenNotifIds.add(n.id);
          _showNotification(n);
          break; // Show newest
        }
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,
        if (_currentNotif != null)
          Positioned(
            top: topPadding + 8,
            left: 14,
            right: 14,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                      // Swiped up to dismiss
                      _dismissNotification();
                    }
                  },
                  onTap: () {
                    _dismissNotification();
                    try {
                      GoRouter.of(context).push('/notifications');
                    } catch (_) {}
                  },
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(18),
                    shadowColor: Colors.black.withOpacity(0.35),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF2E7D32),
                            Color(0xFF1B5E20),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF81C784).withOpacity(0.7),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amberAccent.withOpacity(0.6), width: 1),
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: Colors.amberAccent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          '📢 NEW BROADCAST',
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '• Just Now',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: _dismissNotification,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentNotif!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_currentNotif!.body.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    _currentNotif!.body,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
