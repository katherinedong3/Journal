import 'dart:async';
import 'dart:convert';
import 'package:at_client_mobile/at_client_mobile.dart';

import '../at_collection_model.dart' as journal; // Add alias

import 'package:journal/at_collection/at_collection/collection_util.dart';
import 'package:journal/at_collection/at_collection/collections.dart';
import 'package:at_utils/at_logger.dart';
import 'collection_methods_impl.dart';

class AtCollectionModelOperationsImpl<T> implements AtCollectionModelOperations {
  final _logger = AtSignLogger('AtCollectionModelOperationsImpl');
  late journal.AtCollectionModel<T> atCollectionModel; // Use prefixed model
  late AtCollectionMethodImpl collectionMethodImpl;

  AtCollectionModelOperationsImpl(this.atCollectionModel) {
    collectionMethodImpl = AtCollectionMethodImpl<T>(atCollectionModel as AtCollectionModel<T>);
  }

  @override
  Future<bool> save(
      {bool autoReshare = true, ObjectLifeCycleOptions? options}) async {
    var jsonObject = CollectionUtil.initAndValidateJson(
      collectionModelJson: toJson(),
      id: atCollectionModel.id,
      collectionName: atCollectionModel.collectionName,
      namespace: atCollectionModel.namespace,
    );

    final Completer<bool> completer = Completer<bool>();

    bool? isSelfKeySaved, isAllKeySaved = true;

    await collectionMethodImpl
        .save(
          jsonEncodedData: jsonEncode(jsonObject),
          options: options,
          share: autoReshare,
        )
        .forEach((AtOperationItemStatus atOperationItemStatus) {
      isSelfKeySaved ??= atOperationItemStatus.complete;

      if (!atOperationItemStatus.complete) {
        isAllKeySaved = false;
      }
    });

    completer.complete(autoReshare ? isAllKeySaved : isSelfKeySaved);
    return completer.future;
  }

  @override
  Future<List<String>> sharedWith() async {
    CollectionUtil.checkForNullOrEmptyValues(
      atCollectionModel.id,
      atCollectionModel.collectionName,
      atCollectionModel.namespace,
    );

    final sharedWithList = <String>[];
    final formattedId = CollectionUtil.format(atCollectionModel.id);
    final formattedCollectionName =
        CollectionUtil.format(atCollectionModel.collectionName);

    final allKeys = await _getAtClient().getAtKeys(
      regex: CollectionUtil.makeRegex(
        formattedId: formattedId,
        collectionName: formattedCollectionName,
        namespace: atCollectionModel.namespace,
      ),
    );

    for (final atKey in allKeys) {
      if (atKey.sharedWith != null) {
        _logger.finest('Adding shared with of $atKey');
        sharedWithList.add(atKey.sharedWith!);
      }
    }

    return sharedWithList;
  }

  @override
  Future<bool> share(List<String> atSigns,
      {ObjectLifeCycleOptions? options}) async {
    final jsonObject = CollectionUtil.initAndValidateJson(
      collectionModelJson: toJson(),
      id: atCollectionModel.id,
      collectionName: atCollectionModel.collectionName,
      namespace: atCollectionModel.namespace,
    );

    final allSharedKeyStatus = <AtOperationItemStatus>[];

    await collectionMethodImpl
        .shareWith(
          atSigns,
          jsonEncodedData: jsonEncode(jsonObject),
          options: options,
        )
        .forEach(allSharedKeyStatus.add);

    return allSharedKeyStatus.every((status) => status.complete);
  }

  @override
  Future<bool> delete() async {
    CollectionUtil.checkForNullOrEmptyValues(
      atCollectionModel.id,
      atCollectionModel.collectionName,
      atCollectionModel.namespace,
    );

    bool isSelfKeyDeleted = false;

    await collectionMethodImpl.delete().forEach((event) {
      if (event.complete) {
        isSelfKeyDeleted = true;
      }
    });

    if (!isSelfKeyDeleted) return false;

    bool isAllShareKeysUnshared = true;

    await collectionMethodImpl.unshare().forEach((event) {
      if (!event.complete) {
        isAllShareKeysUnshared = false;
      }
    });

    return isAllShareKeysUnshared;
  }

  @override
  Future<bool> unshare({List<String>? atSigns}) async {
    bool isAllShareKeysUnshared = true;

    await collectionMethodImpl.unshare(atSigns: atSigns).forEach((event) {
      if (!event.complete) {
        isAllShareKeysUnshared = false;
      }
    });

    return isAllShareKeysUnshared;
  }

  AtClient _getAtClient() => AtClientManager.getInstance().atClient;

  @override
  fromJson(Map<String, dynamic> jsonObject) {
    return atCollectionModel.fromJson(jsonObject);
  }

  @override
  Map<String, dynamic> toJson() {
    return atCollectionModel.toJson();
  }
}
