import 'package:flutter/material.dart';

import 'screens/satacenter_chat_page.dart';
import 'services/satacenter_api.dart';

void main() {
  runApp(const SatacenterApp());
}

class SatacenterApp extends StatelessWidget {
  const SatacenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satacenter Gabes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6B5C)),
        useMaterial3: true,
      ),
      home: SatacenterChatPage(
        api: SatacenterApi(
          baseUrl: 'http://127.0.0.1:8000',
        ),
      ),
    );
  }
}
