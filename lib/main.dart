import 'package:flutter/material.dart';
import 'screens/galeria_screen.dart';
import 'screens/juegos_screen.dart';
import 'screens/maquinas_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuchillasApp());
}

// Paleta cobre: blanco + gama de oxidación (naranja → cobre → pátina verde).
const cobre = Color(0xFFB87333);
const cobreOscuro = Color(0xFF8C5A22);
const naranjaCobre = Color(0xFFD9782D);
const patina = Color(0xFF2E9C8A);

class CuchillasApp extends StatelessWidget {
  const CuchillasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuchillas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'D-DIN',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: cobre,
          onPrimary: Colors.white,
          secondary: patina,
          onSecondary: Colors.white,
          tertiary: naranjaCobre,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: cobreOscuro,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'D-DIN',
            color: cobreOscuro,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cobre.withOpacity(0.35), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: cobre,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 60),
            textStyle: const TextStyle(
                fontFamily: 'D-DIN', fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cobreOscuro,
            side: const BorderSide(color: cobre, width: 1.5),
          ),
        ),
        chipTheme: const ChipThemeData(
          selectedColor: patina,
          labelStyle: TextStyle(fontFamily: 'D-DIN'),
          secondaryLabelStyle: TextStyle(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: naranjaCobre,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: cobre.withOpacity(0.18),
          iconTheme: WidgetStatePropertyAll(
              const IconThemeData(color: cobreOscuro, size: 28)),
          labelTextStyle: const WidgetStatePropertyAll(TextStyle(
              fontFamily: 'D-DIN',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cobreOscuro)),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          JuegosScreen(),
          GaleriaScreen(),
          MaquinasScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.hardware), label: 'Juegos'),
          NavigationDestination(
              icon: Icon(Icons.photo_library), label: 'Galería'),
          NavigationDestination(
              icon: Icon(Icons.precision_manufacturing), label: 'Máquinas'),
        ],
      ),
    );
  }
}
