// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:core';

import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> processInput(
    String input, String keywordsFile) async {
  List<String>? reservedKeywords;
  String jsonString = await rootBundle.loadString(keywordsFile);
  ;
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  reservedKeywords = List<String>.from(jsonData['keywords']);
  var symbolReplacements = <String, String>{};
  var deAnonymizeKey = <String>[];
  final regex = RegExp(r"\b[a-zA-Z_$][a-zA-Z_$\d]*\b");
  var newInput = input.replaceAllMapped(regex, (match) {
    final identifier = match.group(0)!;
    if (reservedKeywords!.contains(identifier)) {
      return identifier;
    }

    String singleLetter = "";

    if (symbolReplacements.keys.contains(identifier)) {
      singleLetter = symbolReplacements[identifier]!;
    } else {
      singleLetter = getSingleLetter(symbolReplacements);
      symbolReplacements[identifier] = singleLetter;
      deAnonymizeKey.add('$identifier|$singleLetter');
    }

    return singleLetter;
  });
  return {'deAnonymizeKey': deAnonymizeKey, 'anonymizedCode': newInput};
}

String getSingleLetter(Map<String, String> symbolReplacements) {
  if (symbolReplacements.isEmpty) {
    return 'ⓐ';
  }
  var lastLetter = symbolReplacements.values.last;
  var lastLetterCode = lastLetter.codeUnits.last;
  if (lastLetterCode == 'ⓩ'.codeUnits.first) {
    lastLetter = 'ⓐ' * (lastLetter.length + 1);
  } else {
    lastLetter = lastLetter.substring(0, lastLetter.length - 1) +
        String.fromCharCode(lastLetterCode + 1);
  }
  return lastLetter;
}

String reverse(Map<String, dynamic> processedInput) {
  var deAnonymizeKey = processedInput['deAnonymizeKey'] as List<String>;
  var anonymizedCode = processedInput['anonymizedCode'] as String;
  var identifierMap = <String, String>{};
  for (var key in deAnonymizeKey.reversed) {
    final keySplit = key.split('|');
    identifierMap[keySplit[1]] = keySplit[0];
  }
  for (var anonymizedIdentifier in identifierMap.keys) {
    anonymizedCode = anonymizedCode.replaceAll(
        anonymizedIdentifier, identifierMap[anonymizedIdentifier] ?? "");
  }
  return anonymizedCode;
}
