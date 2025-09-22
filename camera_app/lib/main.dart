import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color.fromARGB(255, 40, 41, 51), // dark gray
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 23, 25, 41), // slightly lighter than pure black
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
),
  home: const CameraScreen(),
    );
  }
}

