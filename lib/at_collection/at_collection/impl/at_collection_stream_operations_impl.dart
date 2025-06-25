import 'dart:convert';
import 'package:at_client/src/at_collection/at_collection_model.dart';
import 'package:journal/at_collection/at_collection/at_collection_model.dart' as journal;
import 'package:journal/at_collection/at_collection/collection_util.dart';
import 'package:journal/at_collection/at_collection/collections.dart';

import 'collection_methods_impl.dart';

class AtCollectionModelStreamOperationsImpl<T> extends AtCollectionModelStreamOperations {
  late journal.AtCollectionModel<T> atCollectionModel;
  late AtCollectionMethodImpl _collectionMethodImpl;

  AtCollectionModelStreamOperationsImpl(this.atCollectionModel) {
    _collectionMethodImpl = AtCollectionMethodImpl<T>(atCollectionModel as AtCollectionModel<T>);
  }

  @override
  Stream<AtOperationItemStatus> save({bool share = true, ObjectLifeCycleOptions? options}) async* {
    var jsonObject = CollectionUtil.initAndValidateJson(
      collectionModelJson: atCollectionModel.toJson(),
      id: atCollectionModel.id,
      collectionName: atCollectionModel.collectionName,
      namespace: atCollectionModel.namespace,
    );

    yield* _collectionMethodImpl.save(
      jsonEncodedData: jsonEncode(jsonObject),
      options: options,
      share: share,
    );
  }

  @override
  Stream<AtOperationItemStatus> share(List<String> atSigns, {ObjectLifeCycleOptions? options}) async* {
    var jsonObject = CollectionUtil.initAndValidateJson(
      collectionModelJson: atCollectionModel.toJson(),
      id: atCollectionModel.id,
      collectionName: atCollectionModel.collectionName,
      namespace: atCollectionModel.namespace,
    );

    yield* _collectionMethodImpl.shareWith(
      atSigns,
      jsonEncodedData: jsonEncode(jsonObject),
      options: options,
    );
  }

  @override
  Stream<AtOperationItemStatus> delete() async* {
    CollectionUtil.checkForNullOrEmptyValues(
      atCollectionModel.id,
      atCollectionModel.collectionName,
      atCollectionModel.namespace,
    );

    yield* _collectionMethodImpl.delete();
    yield* _collectionMethodImpl.unshare();
  }

  @override
  Stream<AtOperationItemStatus> unshare({List<String>? atSigns}) async* {
    yield* _collectionMethodImpl.unshare(atSigns: atSigns);
  }
}
