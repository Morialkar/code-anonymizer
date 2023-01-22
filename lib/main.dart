import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/anonymize.dart';

enum AppState { anonymize, anonymizeResult, deanonymize, deanonymizeResult }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Anonymizer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'Anonymisateur de code pour Chat GPT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController anonymizeTextarea = TextEditingController();
  TextEditingController deanonymizeTextarea = TextEditingController();
  TextEditingController deanonymizeKeyTextarea = TextEditingController();
  String _deanonymizeKeyString = "";
  String _anonymizedValue = "";
  String _deanonymizedString = "";
  AppState _state = AppState.anonymize;

  String? _selectedFile;
  final List<DropdownMenuItem> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void anonymizeString() async {
    if (anonymizeTextarea.text == "" || _selectedFile == null) return;
    Map<String, dynamic> anonymizedData =
        await processInput(anonymizeTextarea.text, _selectedFile!);
    setState(() {
      _deanonymizeKeyString = anonymizedData["deAnonymizeKey"].join(',');
      _anonymizedValue = anonymizedData["anonymizedCode"];
      _state = AppState.anonymizeResult;
    });
    return;
  }

  void deanonymizeString() {
    if (deanonymizeTextarea.text == "" || deanonymizeKeyTextarea.text == "") {
      return;
    }
    setState(() {
      _deanonymizedString = reverse({
        "deAnonymizeKey": deanonymizeKeyTextarea.text.split(','),
        "anonymizedCode": deanonymizeTextarea.text
      });
      _state = AppState.deanonymizeResult;
    });
    return;
  }

  void _loadFiles() async {
    String assetManifest = await rootBundle.loadString('AssetManifest.json');
    Map<String, dynamic> assetMap = jsonDecode(assetManifest);
    assetMap.forEach((file, value) {
      if (file.startsWith('lib/reservedKeywords/')) {
        var fileName = file.split("/").last;
        var fileNameWithoutExtension = fileName.split(".")[0];
        setState(() {
          _files.add(
            DropdownMenuItem(
              value: value[0],
              child: Text(fileNameWithoutExtension),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      floatingActionButton: () {
        switch (_state) {
          case AppState.anonymize:
            return FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _state = AppState.deanonymize;
                  });
                },
                child: const Icon(Icons.logout));

          case AppState.deanonymize:
            return FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _state = AppState.anonymize;
                  });
                },
                child: const Icon(Icons.login));

          case AppState.anonymizeResult:
          case AppState.deanonymizeResult:
            return FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _anonymizedValue = "";
                    _deanonymizedString = "";
                    _deanonymizeKeyString = "";
                    anonymizeTextarea.text = "";
                    deanonymizeTextarea.text = "";
                    deanonymizeKeyTextarea.text = "";

                    _state = _state == AppState.anonymizeResult
                        ? AppState.anonymize
                        : AppState.deanonymize;
                  });
                },
                child: const Icon(Icons.refresh));
          default:
        }
      }(),
      body: Container(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        padding: const EdgeInsets.all(20),
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).

          mainAxisAlignment: MainAxisAlignment.center,
          children: () {
            switch (_state) {
              case AppState.anonymize:
                return <Widget>[
                  Row(
                    children: [
                      const Text(
                        "Entrez votre code pour l'anonymizer puis sélectionnez un language:",
                      ),
                      DropdownButton(
                        items: _files,
                        onChanged: (value) {
                          setState(() {
                            _selectedFile = value;
                          });
                        },
                        value: _selectedFile,
                        hint: const Text('Selectionnez un language'),
                      ),
                    ],
                  ),
                  TextField(
                    controller: anonymizeTextarea,
                    keyboardType: TextInputType.multiline,
                    maxLines: 10,
                  ),
                  ElevatedButton(
                      onPressed: anonymizeString,
                      child: const Text("Cliquez pour anonymiser"))
                ];
              case AppState.deanonymize:
                return <Widget>[
                  const Text(
                    "Entrez votre code pour le dé-anonymiser:",
                  ),
                  TextField(
                    controller: deanonymizeTextarea,
                    keyboardType: TextInputType.multiline,
                    maxLines: 10,
                  ),
                  const Text(
                    "Puis entrez votre clé de dé-anonymisation:",
                  ),
                  TextField(
                    controller: deanonymizeKeyTextarea,
                    keyboardType: TextInputType.multiline,
                    maxLines: 2,
                  ),
                  ElevatedButton(
                      onPressed: deanonymizeString,
                      child: const Text("Cliquez pour dé-anonymiser"))
                ];
              case AppState.anonymizeResult:
                return <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Votre code anonymisé"),
                        ElevatedButton(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: _anonymizedValue)),
                            child: const Icon(Icons.copy_all))
                      ]),
                  Text(_anonymizedValue),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Votre clé de dé-anonymisation"),
                        ElevatedButton(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: _deanonymizeKeyString)),
                            child: const Icon(Icons.copy_all))
                      ]),
                  Text(_deanonymizeKeyString),
                ];
              case AppState.deanonymizeResult:
                return <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Votre code dé-anonymisé"),
                        ElevatedButton(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: _deanonymizedString)),
                            child: const Icon(Icons.copy_all))
                      ]),
                  Text(_deanonymizedString),
                ];
              default:
                return [const Text("_state error")];
            }
          }(),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
