import 'package:at_client/at_client.dart';
import 'package:at_client/at_collection/at_collection_model.dart';


class JournalEntry extends AtCollectionModel {
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

  /// Create a proposal from this entry for sharing with another user
  AtCollectionProposal toProposal(String recipientAtsign, {String? note}) {
    return AtCollectionProposal(
      entryId: id,
      recipient: recipientAtsign,
      proposedData: toJson(),
      note: note,
    );
  }

  /// Apply a proposal update to this journal entry
  void applyProposalUpdate(Map<String, dynamic> proposedData) {
    title = proposedData['title'] ?? title;
    description = proposedData['description'] ?? description;
    content = proposedData['content'] ?? content;
  }

  /// Check if this entry is editable by the current atSign
  bool get isEditable => metadata?[AtCollectionConstants.permissionEdit] == true;

  /// Remove edit access to this entry from a given atSign
  Future<void> revokeAccess(String atsign) async {
    await AtCollection().unshareEntryWith(entry: this, sharedWith: atsign);
  }

  /// Send this entry to another user for edit proposal
  Future<void> proposeEditTo(String recipientAtsign, {String? note}) async {
    final proposal = toProposal(recipientAtsign, note: note);
    await AtCollection().sendProposal(proposal);
  }

  /// Accept a received proposal (modifies the entry)
  Future<void> acceptProposal(AtCollectionProposal proposal) async {
    applyProposalUpdate(proposal.proposedData);
    await AtCollection().updateEntry(this);
  }

  /// Reject a proposal (optionally notify sender)
  Future<void> rejectProposal(AtCollectionProposal proposal, {String? rejectionNote}) async {
    await AtCollection().rejectProposal(proposal, rejectionNote: rejectionNote);
  }
}
