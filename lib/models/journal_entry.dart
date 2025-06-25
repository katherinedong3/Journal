///import 'package:at_client/at_client.dart';
import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_client/src/at_collection/at_collection_model.dart';
import 'package:journal/at_collection/at_collection/at_collection_model.dart' as journal;
///import 'package:journal/at_collection/at_collection/collections.dart';
import 'package:journal/at_collection/at_collection_proposal.dart'; 
import 'package:journal/at_collection/at_collection_proposal_service.dart';

class JournalEntry extends journal.AtCollectionModel<Map<String, dynamic>> {
  String? title;
  String? description;
  String? content;

  JournalEntry({
    required String id,
    this.title,
    this.description,
    this.content,
    DateTime? createdAt,
  }) {
    this.id = id;
    this.createdAt = createdAt ?? DateTime.now();
    namespace = 'journal';
    collectionName = 'entry';
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'content': content,
      };

  @override
  void fromJson(Map<String, dynamic> json) {
    title = json['title'];
    description = json['description'];
    content = json['content'];
  }

  AtCollectionProposal toProposal(String recipientAtsign, {String? note}) {
    return AtCollectionProposal(
      entryId: id,
      recipient: recipientAtsign,
      proposedData: toJson(),
      note: note, sender: '',
    );
  }

  void applyProposalUpdate(Map<String, dynamic> proposedData) {
    title = proposedData['title'] ?? title;
    description = proposedData['description'] ?? description;
    content = proposedData['content'] ?? content;
  }

  /// Instead of using metadata constants, you could define your own metadata structure.
  bool get isEditable {
    final permissions = metadata?['permissions'];
    if (permissions is Map<String, dynamic>) {
      return permissions['edit'] == true;
    }
    return false;
  }
  
  get metadata => null;
  
   //Private backing field for createdAt
  DateTime? _createdAt;

  // public getter
  DateTime? get createdAt => _createdAt;

  // public setter
  set createdAt(DateTime? value) {
    _createdAt = value;
  }

  /// Callbacks for proposal actions — assumes you’ve implemented a service
  Future<void> proposeEditTo(String recipientAtsign, {String? note}) async {
    final proposal = toProposal(recipientAtsign, note: note);
    await AtCollectionProposalService.sendProposal(proposal);
  }

  static Future<void> acceptProposal<T extends AtCollectionModel<Map<String, dynamic>>>(
    AtCollectionProposal proposal, {
    required T updatedEntry,
  }) async {
    updatedEntry.fromJson(proposal.proposedData);
    final atClient = AtClientManager.getInstance().atClient;
    final atKey = AtKey()
      ..key = updatedEntry.id
      ..sharedWith = null
      ..namespace = updatedEntry.namespace;

    await atClient.put(atKey, jsonEncode(updatedEntry.toJson()));
  }


  Future<void> revokeAccess(String atsign) async {
    await AtCollectionProposalService.unshareEntry(this as AtCollectionModel, atsign);
  }


}
