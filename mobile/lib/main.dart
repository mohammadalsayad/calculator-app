import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
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
  final String baseUrl = "http://localhost:4000";

  final num1Controller = TextEditingController();
  final num2Controller = TextEditingController();

  String status = "";
  Timer? timer;

  Future<void> sendNumbers() async {
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
      status = "بانتظار النتيجة...";
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
        showResult(data["result"]);
      }
    });
  }

  void showResult(Map result) {
    setState(() {
      status = "";
    });

    String message;
    if (result["error"] != null) {
      message = result["error"];
    } else {
      message = "الناتج: ${result["value"]}";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("النتيجة"),
        content: Text(message),
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
