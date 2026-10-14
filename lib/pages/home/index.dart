import 'package:flutter/material.dart';
import 'package:jidiu_diary/pages/home/today.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/pages/home/mine.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: const Text('寄丢日记'),
          actions: [
            IconButton(
              icon: const Icon(Icons.music_note),
              onPressed: () {
                Navigator.pushNamed(context, '/music');
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Navigator.pushNamed(context, '/setting');
              },
            ),
          ],
        ),
      body: IndexedStack(
          index: _currentIndex,
          children: const [
          TodayPage(),
          DiaryPage(),
          MinePage(),
                  ],),
      bottomNavigationBar: NavigationBar(
        height: 70,
          backgroundColor: colorScheme.surface,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: '今天'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '日记'),
        NavigationDestination(icon: Icon(Icons.person_outlined), label: '我的'),
      ])
    );
  }
}
