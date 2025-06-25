import 'package:at_client/at_client.dart';
import 'package:journal/at_collection/at_collection_proposal.dart';

class AtCollectionProposalService {
  static Future<void> sendProposal(AtCollectionProposal proposal) async {
    final atClient = AtClientManager.getInstance().atClient;

    final key = 'proposal:${proposal.entryId}.${DateTime.now().millisecondsSinceEpoch}';
    final atKey = AtKey()
      ..key = key
      ..sharedWith = proposal.recipient
      ..metadata = Metadata()
      ..namespaceAware = proposal.namespace;

    final value = proposal.toJsonString();
    await atClient.put(atKey, value);
  }

  static Future<void> acceptProposal<T extends AtCollectionModel>(
    AtCollectionProposal proposal, {
    required T updatedEntry,
  }) async {
    final atClient = AtClientManager.getInstance().atClient;

    // Update the original entry
    await updatedEntry.save();

    // Send optional message back to sender confirming acceptance
    final replyKey = 'proposal_accepted:${proposal.entryId}';
    final reply = AtKey()
      ..key = replyKey
      ..sharedWith = proposal.sender
      ..metadata = Metadata()
      ..namespaceAware = false;

    final replyValue = 'Your proposal for entry ${proposal.entryId} was accepted.';
    await atClient.put(reply, replyValue);
  }

  static Future<void> rejectProposal(
    AtCollectionProposal proposal, {
    String? rejectionNote,
  }) async {
    final atClient = AtClientManager.getInstance().atClient;

    final replyKey = 'proposal_rejected:${proposal.entryId}';
    final reply = AtKey()
      ..key = replyKey
      ..sharedWith = proposal.sender
      ..metadata = Metadata()
      ..namespaceAware = false;

    final note = rejectionNote ?? 'No reason provided.';
    final replyValue =
        'Your proposal for entry ${proposal.entryId} was rejected. Note: $note';
    await atClient.put(reply, replyValue);
  }

  static Future<void> unshareEntry(
    AtCollectionModel entry,
    String atsign,
  ) async {
    await entry.unshare(atSigns: [atsign]);
  }
}

extension on AtKey {
  set namespaceAware(namespaceAware) {}
}
