import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart'; // استيراد صفحة الاختيار
import 'package:flutter_application_1/wifi_page.dart';
import 'package:flutter_application_1/bluetooth_page.dart';
import 'package:flutter_application_1/serial_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Control',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      // 📍 الصفحة الرئيسية الآن هي home_page.dart
      home: const HomePage(), 
      // 📍 تعريف المسارات (Routes) لسهولة التنقل
      routes: {
        '/wifi': (context) => const WifiPage(),
        '/bluetooth': (context) => const BluetoothPage(),
        '/serial': (context) => const SerialPage(),
      },
    );
  }
}