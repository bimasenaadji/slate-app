import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';
import '../widgets/dialogs/task_dialog.dart';
import '../widgets/feedback/undo_snackbar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/progress_chip.dart';
import '../widgets/home/bottom_pull_indicator.dart';
import '../widgets/task/empty_state.dart';
import '../widgets/task/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // Bottom pull-to-add elastic drag state
  double _bottomPullDistance = 0.0;
  static const double _pullThreshold = 70.0;
  bool _hasReachedThreshold = false;
  bool _isModalOpen = false;

  // Midnight Magic transition state
  double _canvasOpacity = 1.0;
  bool _isMidnightTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register callback for when midnight strikes while app is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).onMidnightMagicTriggered =
          _executeMidnightMagicSequence;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate midnight & carry-over immediately when app returns to foreground
      ref.read(taskProvider.notifier).refreshTasks();
    }
  }

  /// Executes the calming, multi-phase 00:00 Midnight Magic transition
  Future<void> _executeMidnightMagicSequence() async {
    if (_isMidnightTransitioning || !mounted) return;
    _isMidnightTransitioning = true;

    // 1. FASE TARIKAN NAPAS (The Deep Breath): Canvas dims to 85% with gentle haptic
    HapticFeedback.mediumImpact();
    setState(() {
      _canvasOpacity = 0.85;
    });

    await Future.delayed(const Duration(milliseconds: 550));

    // 2. FASE PEMBERSIHAN & TRANSISI SISA TUGAS (The Sweep & Fade to Muted)
    if (mounted) {
      ref.read(taskProvider.notifier).performMidnightMagic();
    }

    await Future.delayed(const Duration(milliseconds: 400));

    // 3. FASE FAJAR (The Dawn): Restore canvas brightness to 100%
    if (mounted) {
      setState(() {
        _canvasOpacity = 1.0;
      });
      _isMidnightTransitioning = false;
    }
  }

  void _openAddTaskModal() {
    if (_isModalOpen) return; // Prevent duplicate modal overlapping
    _isModalOpen = true;

    HapticFeedback.mediumImpact();
    TaskDialog.showCreate(context, onAdd: (title, isForTomorrow) {
      ref
          .read(taskProvider.notifier)
          .addTask(title, isForTomorrow: isForTomorrow);
      if (isForTomorrow) {
        UndoSnackBar.show(
          context,
          message: 'Disimpan untuk besok.',
          onUndo: () {},
          duration: const Duration(seconds: 2),
        );
      }
    }).whenComplete(() {
      if (mounted) {
        _isModalOpen = false;
      }
    });
  }

  /// Calculates non-linear rubber-band resistance for natural elastic tension
  double _calculateRubberBandDistance(double rawDistance) {
    const maxTension = 130.0;
    const factor = 0.55;
    return (rawDistance * factor).clamp(0.0, maxTension);
  }

  void _handlePointerRelease() {
    if (_hasReachedThreshold) {
      _hasReachedThreshold = false;
      setState(() {
        _bottomPullDistance = 0.0;
      });
      _openAddTaskModal();
    } else if (_bottomPullDistance > 0) {
      setState(() {
        _bottomPullDistance = 0.0;
        _hasReachedThreshold = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    final completedCount = tasks.where((t) => t.isDone).length;
    final totalCount = tasks.length;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            opacity: _canvasOpacity,
            child: Stack(
              children: [
                // Pointer Listener detects finger release immediately
                Listener(
                  onPointerUp: (_) => _handlePointerRelease(),
                  onPointerCancel: (_) => _handlePointerRelease(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollUpdateNotification) {
                        if (notification.metrics.pixels >
                            notification.metrics.maxScrollExtent) {
                          final overscroll =
                              notification.metrics.pixels -
                              notification.metrics.maxScrollExtent;
                          final elasticDistance =
                              _calculateRubberBandDistance(overscroll);
                          setState(() {
                            _bottomPullDistance = elasticDistance;
                          });

                          if (_bottomPullDistance >= _pullThreshold &&
                              !_hasReachedThreshold) {
                            _hasReachedThreshold = true;
                            HapticFeedback.lightImpact();
                          } else if (_bottomPullDistance < _pullThreshold &&
                              _hasReachedThreshold) {
                            _hasReachedThreshold = false;
                          }
                        }
                      } else if (notification is OverscrollNotification) {
                        if (notification.overscroll > 0) {
                          final rawDistance =
                              _bottomPullDistance + notification.overscroll;
                          final elasticDistance =
                              _calculateRubberBandDistance(rawDistance);
                          setState(() {
                            _bottomPullDistance = elasticDistance;
                          });

                          if (_bottomPullDistance >= _pullThreshold &&
                              !_hasReachedThreshold) {
                            _hasReachedThreshold = true;
                            HapticFeedback.lightImpact();
                          }
                        }
                      } else if (notification is ScrollEndNotification) {
                        _handlePointerRelease();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: () => notifier.refreshTasks(),
                      color: AppColors.textPrimary,
                      backgroundColor: Colors.white,
                      displacement: 32,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          // 1. Header Section (Greeting, Date, & Plus Button)
                          HomeHeader(
                            onAddTap: _openAddTaskModal,
                          ),

                          // 2. Dynamic Progress Counter Badge
                          ProgressChip(
                            completedCount: completedCount,
                            totalCount: totalCount,
                          ),

                          // Spacer
                          const SliverToBoxAdapter(
                            child: SizedBox(height: AppConstants.paddingMd),
                          ),

                          // 3. Dynamic Body: Empty State OR Reorderable Task List
                          if (tasks.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(),
                            )
                          else
                            SliverReorderableList(
                              key: const ValueKey('sliver_reorderable_task_list'),
                              itemCount: tasks.length,
                              findChildIndexCallback: (Key key) {
                                if (key is ValueKey<String>) {
                                  final index = tasks.indexWhere(
                                    (t) => t.id == key.value,
                                  );
                                  return index != -1 ? index : null;
                                }
                                return null;
                              },
                              onReorderItem: (oldIndex, newIndex) {
                                HapticFeedback.lightImpact();
                                notifier.reorderTasks(oldIndex, newIndex);
                              },
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    final animValue = Curves.easeInOut
                                        .transform(animation.value);
                                    return Transform.scale(
                                      scale: 1.0 + (0.03 * animValue),
                                      child: Material(
                                        color: Colors.transparent,
                                        shadowColor: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
                                        elevation: 16 * animValue,
                                        borderRadius: BorderRadius.circular(
                                          AppShapes.radiusLg,
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: child,
                                );
                              },
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey(task.id),
                                  index: index,
                                  child: TaskCard(
                                    key: ValueKey('task_card_${task.id}'),
                                    task: task,
                                    onToggle: () {
                                      final willBeDone = !task.isDone;
                                      notifier.toggleTask(task.id);
                                      if (willBeDone) {
                                        UndoSnackBar.show(
                                          context,
                                          message: 'Tugas diselesaikan.',
                                          onUndo: () =>
                                              notifier.toggleTask(task.id),
                                        );
                                      }
                                    },
                                    onDelete: () {
                                      notifier.deleteTask(task.id);
                                      UndoSnackBar.show(
                                        context,
                                        message: 'Tugas dihapus.',
                                        onUndo: () =>
                                            notifier.restoreTask(task),
                                      );
                                    },
                                    onEdit: (newTitle) =>
                                        notifier.updateTask(task.id, newTitle),
                                  ),
                                );
                              },
                            ),

                          // Bottom comfortable scroll clearance
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Animated Bottom Pull-to-Add Floating Indicator
                BottomPullIndicator(
                  pullDistance: _bottomPullDistance,
                  threshold: _pullThreshold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
