import 'package:flutter/material.dart';
import 'screens/juegos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuchillasApp());
}

class CuchillasApp extends StatelessWidget {
  const CuchillasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuchillas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        // Botones grandes: uso con guantes y poca luz.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 60),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      home: const JuegosScreen(),
    );
  }
}
