import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:journal/models/journal_entry.dart';

enum ProposalStatus {
  pending,
  accepted,
  rejected,
}

class AtCollectionProposal {
  /// Unique ID of the entry this proposal applies to
  final String entryId;

  /// Who is proposing the edit
  final String sender;

  /// Who should receive this proposal (original entry owner)
  final String recipient;

  /// The proposed changes to apply to the entry
  final Map<String, dynamic> proposedData;

  /// Optional message/note from the sender
  final String? note;

  /// When the proposal was sent
  final DateTime timestamp;

  /// Status of the proposal (pending, accepted, rejected)
  ProposalStatus status;

  AtCollectionProposal({
    required this.entryId,
    required this.sender,
    required this.recipient,
    required this.proposedData,
    this.note,
    DateTime? timestamp,
    this.status = ProposalStatus.pending,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to a serializable Map for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'sender': sender,
      'recipient': recipient,
      'proposedData': proposedData,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  /// Reconstruct from a stored/transmitted map
  factory AtCollectionProposal.fromJson(Map<String, dynamic> json) {
    return AtCollectionProposal(
      entryId: json['entryId'],
      sender: json['sender'],
      recipient: json['recipient'],
      proposedData: Map<String, dynamic>.from(json['proposedData']),
      note: json['note'],
      timestamp: DateTime.parse(json['timestamp']),
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProposalStatus.pending,
      ),
    );
  }

  get namespace => null;

  Future<void> sendProposal(JournalEntry updatedEntry, String recipientAtSign, {String? note}) async {
    final proposal = AtCollectionProposal(
      entryId: updatedEntry.id,
      recipient: recipientAtSign,
      proposedData: updatedEntry.toJson(),
      note: note, sender: '',
    );

    final key = '${updatedEntry.collectionName}_proposal_${updatedEntry.id}_${DateTime.now().millisecondsSinceEpoch}';
    final atKey = AtKey()
      ..key = key
      ..sharedWith = recipientAtSign
      ..namespace = updatedEntry.namespace;

    final value = jsonEncode(proposal.toJson());

    await AtClientManager.getInstance().atClient.put(atKey, value);
  }

  Future<void> acceptProposal(AtCollectionProposal proposal, JournalEntry originalEntry) async {
    // Apply changes to the original entry
    originalEntry.applyProposalUpdate(proposal.proposedData);

    // Update the entry
    await originalEntry.save();

    // Optionally notify the sender
    final notificationKey = 'accepted_proposal_${proposal.entryId}';
    final atKey = AtKey()
      ..key = notificationKey
      ..sharedWith = proposal.recipient
      ..namespace = originalEntry.namespace;

    await AtClientManager.getInstance()
        .atClient
        .put(atKey, jsonEncode({'status': 'accepted'}));
  }



  /// For display/debug
  @override
  String toString() {
    return 'Proposal from @$sender to @$recipient for entry $entryId '
        '[${status.name.toUpperCase()}]';
  }

  toJsonString() {}


}
