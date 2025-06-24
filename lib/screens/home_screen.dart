import 'package:flutter/material.dart';
import 'journal_entry_screen.dart';
import '../models/journal_entry.dart';
import '../services/at_services.dart';
import 'dart:convert';
import 'package:at_client/at_client.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<JournalEntry> entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final keys = await AtService().client.getAtKeys();
    final fetchedEntries = <JournalEntry>[];

    for (final key in keys) {
      if (key.key.startsWith('journal_')) {
        final value = await AtService().client.get(key);
        try {
          final decoded = json.decode(value.value);
          final entry = JournalEntry.fromJson(decoded);
          fetchedEntries.add(entry);
        } catch (_) {}
      }
    }

    setState(() {
      entries = fetchedEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _editEntry(JournalEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(entry: entry),
      ),
    );
    _loadEntries();
  }

  void _deleteEntry(JournalEntry entry) async {
    final key = AtKey()
      ..key = entry.id
      ..namespace = 'journal';

    await AtService().client.delete(key);
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      
      body: entries.isEmpty
          ? const Center(child: Text('No journal entries yet.'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Dismissible(
                  key: Key(entry.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteEntry(entry),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(entry.title),
                    subtitle: Text(entry.createdAt.toLocal().toString()),
                    onTap: () => _editEntry(entry),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
          );
          _loadEntries();
        },
      ),
    );
  }
}