import 'at_collection_model.dart';
import 'package:meta/meta.dart';

@experimental
abstract class AtCollectionModelFactory<T extends AtCollectionModel> {
  /// Expected to return an instance of T
  /// added the parameters for at_jsoncollection_model for create 
  T create(String id, String namespace, String collectionName);

  /// returns [true] if the factory creates instances of atCollectionModel for the given [collectionName]
  bool acceptCollection(String collectionName) {
    return collectionName == T.toString().toLowerCase();
  }

  // In case of conflict priority is used to resolve the right factory for a given collection name
  int priority() {
    return 10;
  }
}

class AtCollectionModelFactoryManager {
  static final AtCollectionModelFactoryManager _singleton =
      AtCollectionModelFactoryManager._internal();

  AtCollectionModelFactoryManager._internal();

  factory AtCollectionModelFactoryManager.getInstance() {
    return _singleton;
  }

  List<AtCollectionModelFactory> collectionFactories = [];

  void register(AtCollectionModelFactory factory) {
    if (!collectionFactories.contains(factory)) {
      collectionFactories.add(factory);
    }
  }

  void unregister(AtCollectionModelFactory factory) {
    if (collectionFactories.contains(factory)) {
      collectionFactories.remove(factory);
    }
  }

  AtCollectionModelFactory<T>? get<T extends AtCollectionModel>(
      String collectionName) {
    AtCollectionModelFactory<T>? maxPriorityCollectionFactory;
    for (AtCollectionModelFactory collectionFactory in collectionFactories) {
      if (collectionFactory.acceptCollection(collectionName)) {
        maxPriorityCollectionFactory ??=
            collectionFactory as AtCollectionModelFactory<T>?;
        if (collectionFactory.priority() >
            maxPriorityCollectionFactory!.priority()) {
          maxPriorityCollectionFactory =
              collectionFactory as AtCollectionModelFactory<T>?;
        }
      }
    }
    return maxPriorityCollectionFactory;
  }
}
