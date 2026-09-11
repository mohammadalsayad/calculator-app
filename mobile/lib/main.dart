import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBQcfLQ_QDqH_09nH9YE71FeTNTaiuMxas",
      appId: "1:164229917363:android:4c3493bbf33b451c331ec6",
      messagingSenderId: "164229917363",
      projectId: "calculator-app-4549a",
      storageBucket: "calculator-app-4549a.firebasestorage.app",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الآلة الحاسبة',
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final String baseUrl = "https://calculator-app-production-3e94.up.railway.app";

  final num1Controller = TextEditingController();
  final num2Controller = TextEditingController();

  String status = "";
  Timer? timer;
  bool resultShown = false;

  @override
  void initState() {
    super.initState();
    setupNotifications();
  }

  Future<void> setupNotifications() async {
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await http.post(
        Uri.parse("$baseUrl/register-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );
    }

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? "النتيجة";
      final body = message.notification?.body ?? "";
      resultShown = true;
      showResultDialog(title, body);
    });
  }

  Future<void> sendNumbers() async {
    resultShown = false;

    setState(() {
      status = "جاري الإرسال...";
    });

    await http.post(
      Uri.parse("$baseUrl/calculate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "num1": num1Controller.text,
        "num2": num2Controller.text,
      }),
    );

    setState(() {
      status = "";
    });

    checkResult();
  }

  void checkResult() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      final response = await http.get(Uri.parse("$baseUrl/result"));
      final data = jsonDecode(response.body);

      if (data["ready"] == true) {
        t.cancel();
        if (!resultShown) {
          final result = data["result"];
          final message = result["error"] ?? "الناتج: ${result["value"]}";
          resultShown = true;
          showResultDialog("النتيجة", message);
        }
      }
    });
  }

  void showResultDialog(String title, String body) {
    setState(() {
      status = "";
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("موافق"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    num1Controller.dispose();
    num2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الآلة الحاسبة")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: num1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "الرقم الأول"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: num2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "الرقم الثاني"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendNumbers,
              child: const Text("إرسال"),
            ),
            const SizedBox(height: 20),
            Text(status),
          ],
        ),
      ),
    );
  }
}
