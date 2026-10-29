import 'package:flutter/material.dart';
import 'data/content.dart';
import 'quiz/quiz.dart';
import 'screens/diary_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/timer_screen.dart';
import 'services/notifications.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Content.load();
  QuizBank.build();
  await appState.load();

  appState.onToast = (msg) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  };

  await Notifications.init();
  // сегодня уже занимались — первое напоминание перенесём на завтра
  appState.onActivityToday = () {
    if (appState.reminder) {
      Notifications.scheduleDaily(appState.reminderMinutes, skipToday: true);
    }
  };
  if (appState.reminder) {
    await Notifications.scheduleDaily(appState.reminderMinutes, skipToday: appState.studiedToday);
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'История Беларуси · ЦТ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scaffoldMessengerKey: messengerKey,
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  static const _titles = ['История Беларуси · ЦТ', 'Практика', 'Дневник', 'Таймер фокуса', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_tab], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  children: [
                    Text('🔥 ${appState.streak}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 12),
                    Text('⚡ ${appState.xp}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: const [
            HomeScreen(),
            PracticeScreen(),
            DiaryScreen(),
            TimerScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Учёба'),
            NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Практика'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Дневник'),
            NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Таймер'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
          ],
        ),
      ),
    );
  }
}
