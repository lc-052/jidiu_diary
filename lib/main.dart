import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/diary_page.dart';
import 'pages/profile_page.dart';
import 'pages/today_page.dart';
import 'state/diary_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = DiaryStore(await SharedPreferences.getInstance())..load();
    runApp(DiaryApp(store: store));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('无法打开本地存储，请重新启动应用。'))),
      ),
    );
  }
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key, required this.store});
  final DiaryStore store;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: store,
    child: Consumer<DiaryStore>(
      builder: (context, state, child) {
        ThemeData theme(Brightness brightness) => ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8854FF),
            brightness: brightness,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        );
        return MaterialApp(
          title: '寄丢日记',
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomePage(),
        );
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              if (context.watch<DiaryStore>().loadError != null)
                MaterialBanner(
                  content: Text(context.read<DiaryStore>().loadError!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      child: const Text('查看说明'),
                    ),
                  ],
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [TodayPage(), DiaryPage(), ProfilePage()],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '今天',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: '日记',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    ),
  );
}
