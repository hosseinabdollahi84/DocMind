import 'dart:io';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      try {
        DynamicLibrary.open("libomp.so");
        // ignore: empty_catches
      } catch (e) {}

      DynamicLibrary.open("libggml-cpu.so");
      DynamicLibrary.open("libggml.so");
      // ignore: empty_catches
    } catch (e) {}

    Llama.libraryPath = "libllama.so";
  }

  runApp(const DocMindApp());
}

class DocMindApp extends StatelessWidget {
  const DocMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
