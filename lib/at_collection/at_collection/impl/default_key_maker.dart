import 'package:at_client/at_client.dart';
import 'package:journal/at_collection/at_collection/collections.dart';

class DefaultKeyMaker implements KeyMaker {
  AtClient _getAtClient() {
    return AtClientManager.getInstance().atClient;
  }

  @override
  AtKey createSelfKey(
      {required String keyId,
      required String collectionName,
      required String namespace,
      ObjectLifeCycleOptions? objectLifeCycleOptions}) {
    return AtKey()
      ..key = '$keyId.$collectionName.atcollectionmodel'
      ..namespace = namespace
      ..metadata = Metadata()
      ..metadata.ccd = objectLifeCycleOptions?.cascadeDelete ?? true
      ..metadata.ttl = objectLifeCycleOptions?.timeToLive?.inMilliseconds
      ..metadata.ttb = objectLifeCycleOptions?.timeToBirth?.inMilliseconds
      ..sharedBy = _getAtClient().getCurrentAtSign();
  }

  @override
  AtKey createSharedKey(
      {required String keyId,
      required String collectionName,
      required String namespace,
      String? sharedWith,
      ObjectLifeCycleOptions? objectLifeCycleOptions}) {
    int? ttrInSeconds =
        objectLifeCycleOptions?.cacheRefreshIntervalOnRecipient.inSeconds;

    return AtKey()
      ..key = '$keyId.$collectionName.atcollectionmodel'
      ..namespace = namespace
      ..sharedWith = sharedWith
      ..metadata = Metadata()
      ..metadata.ttr = ttrInSeconds ?? -1
      ..metadata.ccd = objectLifeCycleOptions?.cascadeDelete ?? true
      ..metadata.ttl = objectLifeCycleOptions?.timeToLive?.inMilliseconds
      ..metadata.ttb = objectLifeCycleOptions?.timeToBirth?.inMilliseconds
      ..sharedBy = _getAtClient().getCurrentAtSign();
  }
}
