import 'package:flutter/material.dart';
import 'package:parsec/parsec.dart';
import 'database_helper.dart';
import 'calculator_history.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String output = "";
  final Parsec parsec = Parsec();
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<CalculatorHistory> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void loadHistory() async {
    history = await dbHelper.getHistory();
    setState(() {});
  }

  void onInput(String buttonText) async {
    setState(() {
      if (buttonText == "C") {
        input = "";
        output = "";
      } else if (buttonText == "=") {
        evaluateExpression();
      } else if (buttonText == "⌫") {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      } else {
        input += buttonText;
      }
    });
  }

  Future<void> evaluateExpression() async {
    try {
      String expression = input.replaceAll('x', '*').replaceAll(':', '/');
      num? result;

      // Mengecek apakah ada simbol akar pangkat n (misalnya, 3√27)
      RegExp exp = RegExp(r'(\d*)√(\d+)');
      Iterable<Match> matches = exp.allMatches(expression);
      if (matches.isNotEmpty) {
        // Menangani simbol akar pangkat n secara manual
        matches.forEach((match) {
          String baseStr = match.group(1)!;
          String radicandStr = match.group(2)!;
          num base = double.parse(baseStr);
          num radicand = double.parse(radicandStr);
          num resultValue = pow(radicand, 1 / base);
          expression =
              expression.replaceFirst(match.group(0)!, resultValue.toString());
        });
      }

      result = await parsec.eval(expression);

      setState(() {
        output = result != null ? result.toString() : "Error";
      });

      if (result != null) {
        CalculatorHistory historyEntry = CalculatorHistory(
          expression: input,
          result: result.toString(),
        );
        await dbHelper.insertHistory(historyEntry);
        loadHistory();
      }
    } catch (e) {
      setState(() {
        output = "Error";
      });
      print("Evaluation error: $e");
    }
  }

  void copyResultToClipboard() {
    Clipboard.setData(
      ClipboardData(text: output),
    ); // Menyalin hasil ke clipboard
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Result copied to clipboard"),
      duration: Duration(seconds: 1),
    ));
  }

  void deleteHistory(int id) async {
    await dbHelper.deleteHistory(id);
    loadHistory();
  }

  void deleteAllHistory() async {
    await dbHelper.deleteAllHistory();
    loadHistory();
  }

  List<String> buttons = [
    "1",
    "2",
    "3",
    "C",
    "4",
    "5",
    "6",
    "⌫",
    "7",
    "8",
    "9",
    "0",
    "-",
    "x",
    ":",
    ".",
    "^",
    "√",
    "+",
    "="
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Calculator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0), // Tinggi divider
          child: Divider(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('Calculator History',
                  style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              tileColor: Colors.black,
              title: Text('Clear All History',
                  style: TextStyle(color: Colors.white)),
              onTap: deleteAllHistory,
              leading: Icon(Icons.clear_all, color: Colors.white),
            ),
            for (var item in history)
              ListTile(
                title: Text(item.expression + " = " + item.result,
                    style: TextStyle(color: Colors.white)),
                tileColor: Colors.black,
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () => deleteHistory(item.id!),
                ),
                onTap: () {
                  setState(() {
                    input = item.expression;
                    output = item.result;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(19).copyWith(bottom: 0),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(input,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 50)),
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      onLongPress: () {
                        copyResultToClipboard();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Result copied to clipboard'),
                        ));
                      },
                      child: Text(output,
                          style: TextStyle(color: Colors.white, fontSize: 80)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Divider(color: Colors.white.withOpacity(0.2)),
          ),
          Padding(
            padding: EdgeInsets.all(11.0),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                Color textColor = Colors.white;
                Color backgroundColor = Colors.grey.withOpacity(0.4);
                if (buttons[index] == "-" ||
                    buttons[index] == ":" ||
                    buttons[index] == "x" ||
                    buttons[index] == "+" ||
                    buttons[index] == "√" ||
                    buttons[index] == "^" ||
                    buttons[index] == ".") {
                  textColor = Colors.green;
                }
                if (buttons[index] == "=") {
                  textColor = Colors.black;
                  backgroundColor = Colors.green;
                }
                if (buttons[index] == "C" || buttons[index] == "⌫") {
                  textColor = Colors.black;
                  backgroundColor = Colors.red;
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    color: backgroundColor,
                    child: Text(
                      buttons[index],
                      style: TextStyle(color: textColor, fontSize: 30),
                    ),
                    onPressed: () {
                      onInput(buttons[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
