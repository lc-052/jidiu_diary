import 'package:flutter/material.dart';

import '../../widgets/today_feature_cards.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.onOpenDiary,
    this.active = true,
    this.todayMood,
    this.selectedDate,
  });
  final int? todayMood;
  final DateTime? selectedDate;
  final bool active;
  final VoidCallback onOpenDiary;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('today-content'),
      primary: widget.active,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        TodayFeatureCards(
          onOpenDiary: widget.onOpenDiary,
          todayMood: widget.todayMood,
          selectedDate: widget.selectedDate,
        ),
      ],
    );
  }
}
