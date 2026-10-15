import 'dart:async';

import 'package:flutter/material.dart';

import '../tarot/daily_tarot_controller.dart';
import '../tarot/tarot_deck.dart';
import '../theme/feature_card_colors.dart';
import '../widgets/app_background.dart';

class TodayTarotCard extends StatefulWidget {
  const TodayTarotCard({super.key, this.controller, this.selectedDate});
  final DailyTarotController? controller;
  final DateTime? selectedDate;
  @override
  State<TodayTarotCard> createState() => _TodayTarotCardState();
}

class _TodayTarotCardState extends State<TodayTarotCard>
    with WidgetsBindingObserver {
  late final _controller = widget.controller ?? DailyTarotController();
  DateTime get _selectedDate =>
      widget.selectedDate ?? DateTime.parse(_controller.date);
  void _scheduleLoad() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) unawaited(_controller.load(forDate: _selectedDate));
  });
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant TodayTarotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) _scheduleLoad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.load(forDate: _selectedDate));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = FeatureCardColors.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final selectedDate = _selectedDate;
        final historical =
            DailyTarotController.dateKey(selectedDate) != _controller.date;
        final draw = _controller.resultForDate(selectedDate);
        return Material(
          color: palette.background,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('today-tarot-button'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyTarotPage(
                  controller: _controller,
                  selectedDate: selectedDate,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    historical ? '当日塔罗' : '今日塔罗',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    draw?.card.name ?? (historical ? '当天未抽牌' : '抽一张牌，给今天一点灵感'),
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: palette.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 60,
                      height: 90,
                      child: draw == null
                          ? const TarotCardBack()
                          : _TarotArtwork(card: draw.card, cacheWidth: 180),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          historical
                              ? (draw == null ? '查看当天记录' : '查看当日解读')
                              : draw == null
                              ? '点击抽牌'
                              : '查看今日解读',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: palette.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DailyTarotPage extends StatefulWidget {
  const DailyTarotPage({
    super.key,
    required this.controller,
    this.selectedDate,
  });
  final DailyTarotController controller;
  final DateTime? selectedDate;
  @override
  State<DailyTarotPage> createState() => _DailyTarotPageState();
}

class _DailyTarotPageState extends State<DailyTarotPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.controller.load(forDate: widget.selectedDate));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.load(forDate: widget.selectedDate));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = FeatureCardColors.of(context);
    final controller = widget.controller;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.selectedDate != null &&
                    DailyTarotController.dateKey(widget.selectedDate!) !=
                        controller.date
                ? '当日塔罗'
                : '今日塔罗',
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final date =
                      widget.selectedDate ?? DateTime.parse(controller.date);
                  final historical =
                      DailyTarotController.dateKey(date) != controller.date;
                  final draw = controller.resultForDate(date);
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${date.year}年${date.month}月${date.day}日',
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              draw?.card.name ??
                                  (historical ? '当天未抽牌' : '与今天的自己相遇'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              draw == null
                                  ? historical
                                        ? '这一天没有保存的塔罗记录。'
                                        : '静下来，想想此刻的感受，再抽一张牌。'
                                  : draw.card.id,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.secondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                            begin: .92,
                                            end: 1,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      ),
                                  child: draw == null
                                      ? const TarotCardBack(
                                          key: ValueKey('tarot-unrevealed'),
                                        )
                                      : _TarotArtwork(
                                          key: ValueKey(draw.card.id),
                                          card: draw.card,
                                          cacheWidth: 720,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (controller.error != null) ...[
                              Text(
                                controller.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.error),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (draw == null && !historical)
                              FilledButton.icon(
                                key: const ValueKey('draw-daily-tarot'),
                                onPressed: controller.busy
                                    ? null
                                    : controller.draw,
                                icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  controller.busy ? '准备中…' : '抽取今日卡牌',
                                ),
                              )
                            else if (draw != null) ...[
                              Text(
                                draw.card.keywords,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                draw.card.guidance,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.8,
                                  color: palette.foreground,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: palette.background,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '留给日记的一个问题',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      draw.card.prompt,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: palette.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              historical
                                  ? '这里展示当天保存的卡牌，历史日期不能补抽。'
                                  : draw == null
                                  ? '每天独立随机抽取一张，记录属于自己的今日灵感。'
                                  : '今日卡牌已保存，明天再来遇见新的灵感。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: palette.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TarotCardBack extends StatelessWidget {
  const TarotCardBack({super.key});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.onPrimary
                .withValues(alpha: .6),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 30,
          ),
        ),
      ),
    ),
  );
}

class _TarotArtwork extends StatelessWidget {
  const _TarotArtwork({
    super.key,
    required this.card,
    required this.cacheWidth,
  });
  final TarotCard card;
  final int cacheWidth;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      card.asset,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      semanticLabel: '寄丢塔罗：${card.name}',
      errorBuilder: (_, _, _) => const Center(child: Text('牌图暂时无法显示')),
    ),
  );
}
