import 'package:flutter/material.dart';
import '../../widgets/week_mood_card.dart';
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView(
        children: [
          WeekMoodCard(),
        ],
      )),
    );
  }
}
