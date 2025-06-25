import 'package:flutter/material.dart';
import 'package:journal/models/SecureJournalEntry.dart';
import 'package:journal/models/journal_entry.dart';
import 'package:journal/services/at_services.dart';
import 'package:at_client/at_client.dart';
import 'dart:convert';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get isEditing => widget.entry != null;
  bool _isSaving = false;
  bool _isPrivate = false;
  bool _showPasswordPrompt = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.entry!.title!;
      _descController.text = widget.entry!.description!;
      if (SecureJournalEntry.isEncrypted(widget.entry!.content!)) {
        _showPasswordPrompt = true;
        _isPrivate = true;
      } else {
        _entryController.text = widget.entry!.content!;
      }
    }
  }

  void _tryDecrypt() {
    final password = _passwordController.text.trim();
    try {
      final decrypted = SecureJournalEntry.decryptContent(widget.entry!.content!, password);
      setState(() {
        _entryController.text = decrypted!;
        _showPasswordPrompt = false;
        _errorMessage = null;
      });
    } catch (_) {
      setState(() => _errorMessage = 'Incorrect password. Try again.');
    }
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final content = _entryController.text.trim();
    final password = _passwordController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    setState(() => _isSaving = true);

    final id = isEditing
        ? widget.entry!.id
        : 'journal_${DateTime.now().millisecondsSinceEpoch}';

    String finalContent = content;
    if (_isPrivate && password.isNotEmpty) {
      finalContent = SecureJournalEntry.encryptContent(content, password);
    }

    final entry = JournalEntry(
      id: id,
      title: title,
      description: description,
      content: finalContent,
      createdAt: isEditing ? widget.entry!.createdAt : DateTime.now(),
    );

    final key = AtKey()
      ..key = id
      ..namespace = 'journal';

    try {
      await AtService().client.put(key, jsonEncode(entry.toJson()));
      AtService().client.syncService.sync();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save entry')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showPasswordPrompt) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Enter Password'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _tryDecrypt,
                child: const Text('Unlock Entry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Journal Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _entryController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Journal Entry',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text("Make entry password protected"),
              value: _isPrivate,
              onChanged: (val) => setState(() => _isPrivate = val!),
            ),
            if (_isPrivate)
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            const SizedBox(height: 12),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveEntry,
                    child: const Text('Save Entry'),
                  ),
          ],
        ),
      ),
    );
  }
}
