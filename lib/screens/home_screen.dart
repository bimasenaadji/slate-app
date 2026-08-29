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
  // Bottom pull-to-add drag state
  double _bottomPullDistance = 0.0;
  static const double _pullThreshold = 60.0;
  bool _hasReachedThreshold = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  void _openAddTaskModal() {
    HapticFeedback.mediumImpact();
    TaskDialog.showCreate(context, onAdd: (title) {
      ref.read(taskProvider.notifier).addTask(title);
    });
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
                        setState(() {
                          _bottomPullDistance = overscroll.clamp(0.0, 110.0);
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
                        setState(() {
                          _bottomPullDistance = (_bottomPullDistance +
                                  notification.overscroll)
                              .clamp(0.0, 110.0);
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
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            notifier.debugInjectCarryOverSample();
                          },
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
                                  final animValue =
                                      Curves.easeInOut.transform(animation.value);
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
    );
  }
}
