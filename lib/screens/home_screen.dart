import 'package:flutter/material.dart';
import 'journal_entry_screen.dart';
import '../models/journal_entry.dart';
import '../services/at_services.dart';
import 'settings_screen.dart';
import 'package:journal/models/journal_entry_utils.dart';


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
    final atClient = AtService().client;
    final fetchedEntries = await fetchJournalEntries(atClient);

    setState(() {
      entries = fetchedEntries
        ..sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);
    });
  }

  void _deleteEntry(JournalEntry entry) async {
    final atClient = AtService().client;
    await entry.delete(); // this works because your entry extends AtCollectionModel
    _loadEntries();
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
                    title: Text(entry.title ?? '(Untitled)'),
                    subtitle: Text(entry.createdAt?.toLocal().toString() ?? ''),
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




