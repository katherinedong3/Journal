import 'dart:convert';
import 'package:at_client/at_client.dart';
import '../models/journal_entry.dart';

Future<List<JournalEntry>> fetchJournalEntries(AtClient atClient) async {
  final keys = await atClient.getKeys(regex: '.entry.journal');
  final entries = <JournalEntry>[];

  for (var keyStr in keys) {
    try {
      final key = AtKey.fromString(keyStr);
      final value = await atClient.get(key);
      final data = jsonDecode(value.value);
      final entry = JournalEntry(id: '')..fromJson(data);
      entries.add(entry);
    } catch (e) {
      // Optionally log error
      continue;
    }
  }

  return entries;
}
