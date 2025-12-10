import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/flashcard.dart';
import 'models/flashcard_deck.dart';
import 'models/note.dart';
import 'models/subject.dart';
import 'models/topic.dart';

import 'pages/flashcard_home_page.dart';
import 'pages/notes_workspace_page.dart';


late Isar isar;

enum AppSection {
  notes,
  flashcards,
  quizzes,
  feynman,
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  isar = await Isar.open(
    [SubjectSchema, TopicSchema, NoteSchema, FlashcardDeckSchema, FlashcardSchema],
    directory: dir.path,
  );

  runApp(const StudyApp());
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final headlineFont = GoogleFonts.spaceGrotesk();
    final bodyFont = GoogleFonts.inter();

    final baseColorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF67E8F9),
      surface: const Color(0xFF161A22),
    ).copyWith(
      primary: const Color(0xFF67E8F9),
      secondary: const Color(0xFF94A3B8),
      surface: const Color(0xFF161A22),
      surfaceContainerHighest: const Color(0xFF141820),
      surfaceContainerHigh: const Color(0xFF141820),
      surfaceContainer: const Color(0xFF141820),
      surfaceContainerLow: const Color(0xFF141820),
      surfaceContainerLowest: const Color(0xFF0F1115),
      onSurface: const Color(0xFFDDE4F0),
      onSurfaceVariant: const Color(0xFF9CA3AF),
      error: const Color(0xFFF43F5E),
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Study App',
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        // Add other supported locales here
      ],
      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: baseColorScheme.surface,
        colorScheme: baseColorScheme,
        cardColor: baseColorScheme.surfaceContainerHighest,
        appBarTheme: AppBarTheme(
          backgroundColor: baseColorScheme.surfaceContainerHighest,
          foregroundColor: baseColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: headlineFont.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: headlineFont.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
            letterSpacing: -0.2,
          ),
          titleMedium: headlineFont.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: baseColorScheme.onSurface,
            letterSpacing: -0.05,
          ),
          bodyLarge: bodyFont.copyWith(
            fontSize: 17,
            height: 1.5,
            color: baseColorScheme.onSurface,
          ),
          bodyMedium: bodyFont.copyWith(
            fontSize: 15,
            height: 1.45,
            color: baseColorScheme.onSurfaceVariant,
          ),
          labelLarge: bodyFont.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: baseColorScheme.onSurface,
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: baseColorScheme.onSurfaceVariant,
          textColor: baseColorScheme.onSurface,
          selectedColor: baseColorScheme.primary,
        ),
        dividerColor: baseColorScheme.onSurface.withValues(alpha: 0.08),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),



      home: const MainScreen(title: 'Main Screen'),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppSection currentSection = AppSection.notes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _navButton("Notes", AppSection.notes),
            const SizedBox(width: 12),
            _navButton("Flashcards", AppSection.flashcards),
            const SizedBox(width: 12),
            _navButton("Quizzes", AppSection.quizzes),
            const SizedBox(width: 12),
            _navButton("Feynman", AppSection.feynman),
          ],
        ),
      ),
      body: _buildSection(),
    );
  }
  
  Widget _buildSection() {
    switch (currentSection) {
      case AppSection.notes:
        return const NotesWorkspacePage();
      case AppSection.flashcards:
        return const FlashcardHomePage();
      case AppSection.quizzes:
        return const QuizPage();
      case AppSection.feynman:
        return const TeachModePage();
    }
  }

  Widget _navButton(String text, AppSection section) {
    final selected = currentSection == section;
    return GestureDetector(
      onTap: () => setState(() => currentSection = section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Quiz Page'));
  }
}

class TeachModePage extends StatelessWidget {
  const TeachModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Teach Mode Page'));
  }
}
