import 'package:applog/applog.dart';

import 'behavior_mixin.dart';

typedef FromMap<E> = E Function(Map<String, dynamic> data, String? key);
typedef ToMap<E> = Map<String, dynamic> Function(E e);
typedef CheckPermission = bool Function();


/// An abstract class that defines a document-based repository interface.
///
/// This interface is intended to be used with a data model (`E`) and a key type (`SK`),
/// providing a standardized way to interact with document stores such as Firebase Firestore.
/// It includes methods for streaming, fetching, and manipulating documents based on their keys.
///
/// The interface utilizes a `BehaviorMixin` to manage the state and caching of the fetched documents.
///
/// Type parameters:
/// - `E`: The entity type that the repository manages.
/// - `SK`: The type of the key that uniquely identifies each document.
///
/// Implementation example of UserDataRepository using Firebase
///
/// ```dart
/// class UserDataRepository extends RepositoryDocumentInterface<UserData, String>
///     with FirebaseCloudfirestoreImpl, NetworkManagerInterface {
///   @override
///   String get repositoryName => 'UserDataRepository';
///
///   @override
///   RepositoryDocumentConfiguration<UserData, String> get configuration =>
///       RepositoryDocumentConfiguration(
///         documentPath: (key) => pathCloudfirestore.userdata(netconfig.uid),
///         streamBuilder: (path, fromMap) => serviceCloudfirestore.streamDocument(
///           path: path,
///           builder: fromMap,
///           onNull: const UserData.empty(),
///         ),
///         set: (path, map) => serviceCloudfirestore.setDocument(path: path, data: map),
///         update: (path, map) => serviceCloudfirestore.updateDocument(path: path, data: map),
///         delete: (path) => serviceCloudfirestore.deleteDocument(path: path),
///         exist: (path) => serviceCloudfirestore.exist(path: path),
///         emptyObject: const UserData.empty(),
///         fromMap: (data, key) => UserDataModel.fromMap(data).toEntity(),
///         toMap: (e) => UserDataModel.fromEntity(e).toMap(),
///       );
/// }
/// ```
abstract class RepositoryDocumentInterface<E, SK> with BehaviorMixin<E> {
  /// Returns the name of the repository for logging and error handling purposes.
  String get repositoryName;

  /// Configuration object that holds all the specific document path builders, stream builders,
  /// and CRUD operations required by the repository to interact with the data store.
  RepositoryDocumentConfiguration<E, SK> get configuration;

  RepositoryDocumentConfiguration<E, SK> get _config => configuration;

  //
  //
  //
  //
  //

  Stream<E> _streamBuilder(SK key) =>
      _config.streamBuilder(_config.documentPath(key), _config.fromMap);

  bool _isPermissionDeni(String method, CheckPermission? customPermissions) {
    if (!(customPermissions?.call() ?? _config.checkPermission.call())) {
      AppLog.error('Permission Deni', repositoryName, method);
      return true;
    }
    return false;
  }

  /// Provides a stream of entities from the repository for a specific key, handling permissions and errors.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK` for which the stream is requested.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  Stream<E> stream({required SK key, CheckPermission? customPermission}) {
    if (_isPermissionDeni('stream', customPermission)) {
      return const Stream.empty();
    }
    try {
      return _streamBuilder(key);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'stream');
      return const Stream.empty();
    }
  }

  /// Fetches a single document of type `E` asynchronously based on the specified key, handling permissions and errors.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  Future<E> fetch({required SK key, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('fetch', customPermission)) {
      return _config.emptyObject;
    }
    try {
      return await fetchBehaviorValue(stream: _streamBuilder(key)) ?? _config.emptyObject;
    } catch (e) {
      AppLog.error('$e', repositoryName, 'fetch');
      return _config.emptyObject;
    }
  }

  /// Gets the cached value of type `E` if available, handling permissions and errors.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  E? cache({required SK key, CheckPermission? customPermission}) {
    if (_isPermissionDeni('cache', customPermission)) {
      return null;
    }
    try {
      return getBehaviorValue();
    } catch (e) {
      AppLog.error('$e', repositoryName, 'cache');
    }
    return null;
  }

  /// Sets a document in the data store with the given key and entity data, handling permissions and errors.
  ///
  /// This method attempts to create or replace a document at the specified key with the new entity data.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [e]: The entity of type `E` to set at the specified key.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully set, otherwise `false`.
  Future<bool> set({required SK key, required E e, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('set', customPermission)) {
      return false;
    }
    try {
      return _config.set(_config.documentPath(key), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'set');
      return false;
    }
  }

  /// Updates an existing document with new data, handling permissions and errors.
  ///
  /// This method updates a document at the specified key with the provided entity data.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [e]: The updated entity of type `E` to store at the specified key.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully updated, otherwise `false`.
  Future<bool> update({required SK key, required E e, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('update', customPermission)) {
      return false;
    }
    try {
      return _config.update(_config.documentPath(key), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'update');
      return false;
    }
  }

  /// Updates specific fields of a document at the given key, handling permissions and errors.
  ///
  /// This method allows for partial updates to a document, modifying only the specified fields.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [data]: A map of fields and values that specify what should be updated.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the fields were successfully updated, otherwise `false`.
  Future<bool> updateValue(
      {required SK key,
      required Map<String, dynamic> data,
      CheckPermission? customPermission}) async {
    if (_isPermissionDeni('updateValue', customPermission)) {
      return false;
    }
    try {
      return _config.update(_config.documentPath(key), data);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'updateValue');
      return false;
    }
  }

  /// Deletes a document at the specified key, handling permissions and errors.
  ///
  /// This method attempts to delete a document at the given key. It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [key]: The document key of type `SK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully deleted, otherwise `false`.
  Future<bool> delete({required SK key, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('delete', customPermission)) {
      return false;
    }
    try {
      return _config.delete(_config.documentPath(key));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'delete');
      return false;
    }
  }

  /// Checks if a document exists at the specified key, handling permissions and errors.
  ///
  /// This method checks for the existence of a document at the given key and returns true if it exists.
  ///
  /// Parameters:
  /// - [singleKey]: The document key of type `SK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document exists, otherwise `false`.
  Future<bool> exist({required SK singleKey, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('exist', customPermission)) {
      return false;
    }
    try {
      return await _config.exist(_config.documentPath(singleKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'exist');
      return false;
    }
  }
}

/// An abstract class that defines a repository interface for managing collections of documents.
///
/// This interface is intended for use with a data model (`E`) along with three types of keys:
/// - `LK` for identifying the collection path,
/// - `SK` for the path of individual documents within a collection,
/// - `BK` for caching and retrieving lists of documents.
///
/// The interface utilizes a `BehaviorListMixin` to manage the state and caching of fetched document lists.
///
/// Type parameters:
/// - `E`: The entity type that the repository manages within collections.
/// - `LK`: The type used to determine the path of a collection.
/// - `SK`: The type used for identifying individual documents within a collection.
/// - `BK`: The type used for caching and keying lists of documents.
abstract class RepositoryCollectionInterface<E, LK, SK, BK> with BehaviorListMixin<BK, List<E>> {
  /// Returns the name of the repository for logging and error handling purposes.
  String get repositoryName;

  /// Configuration object that holds all the specific collection path builders, stream builders,
  /// and CRUD operations required by the repository to interact with the data store.
  RepositoryCollectionConfiguration<E, LK, SK, BK> get configuration;

  RepositoryCollectionConfiguration<E, LK, SK, BK> get _config => configuration;

  //
  //
  //
  //

  Stream<List<E>> _streamCollectionBuilder(LK listKey) =>
      _config.streamCollectionBuilder(_config.collectionPath(listKey), _config.fromMap);

  bool _isPermissionDeni(String method, CheckPermission? customPermissions) {
    if (!(customPermissions?.call() ?? _config.checkPermission.call())) {
      AppLog.error('Permission Deni', repositoryName, method);
      return true;
    }
    return false;
  }

  /// Provides a stream of entire collections from the repository for a specific collection key, handling permissions and errors.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK` for which the stream is requested.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A stream of lists of entities `E` if permissions are granted and no errors occur, otherwise an empty stream.
  Stream<List<E>> streamAll({required LK listKey, CheckPermission? customPermission}) {
    if (_isPermissionDeni('streamAll', customPermission)) {
      return const Stream.empty();
    }
    try {
      return getBehaviourStream(_config.cacheKeyEncoder(listKey),
          stream: _streamCollectionBuilder(listKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'streamAll');
      return const Stream.empty();
    }
  }

  /// Streams a single entity `E` from a collection identified by `listKey` and filtered by `singleKey`.
  ///
  /// This method retrieves a stream for a single document within a collection. If permissions are denied or an error occurs,
  /// an empty stream is returned. It uses the `streamAll` method to fetch the collection and then filters the list
  /// to find the first element matching `singleKey`.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The key of the specific entity to stream within the collection.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A stream containing a single entity `E` if found, otherwise an empty stream.
  Stream<E> streamSingle(
      {required LK listKey, required SK singleKey, CheckPermission? customPermission}) {
    if (_isPermissionDeni('streamSingle', customPermission)) {
      return const Stream.empty();
    }
    try {
      return streamAll(listKey: listKey).map((l) =>
          l.firstWhere((e) => _config.hasKey(e, singleKey), orElse: () => _config.emptyObject));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'streamSingle');
      return const Stream.empty();
    }
  }

  /// Fetches all entities `E` within a collection identified by `listKey`.
  ///
  /// This method asynchronously retrieves all documents within a specified collection, handling permissions and errors.
  /// If permissions are denied or an error occurs, it returns an empty list.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future` that resolves to a list of entities `E`.
  Future<List<E>> fetchAll({required LK listKey, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('fetchAll', customPermission)) {
      return [];
    }
    try {
      return await fetchBehaviourValue(_config.cacheKeyEncoder(listKey),
              stream: _streamCollectionBuilder(listKey)) ??
          [];
    } catch (e) {
      AppLog.error('$e', repositoryName, 'fetchAll');
      return [];
    }
  }

  /// Fetches a single entity `E` from a collection identified by `listKey` and filtered by `singleKey`.
  ///
  /// This method asynchronously retrieves a specific document within a collection, handling permissions and errors.
  /// If permissions are denied or an error occurs, it returns a default empty entity.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The key of the specific entity to fetch within the collection.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future` that resolves to an entity `E` if found, otherwise a default empty entity.
  Future<E> fetchSingle(
      {required LK listKey, required SK singleKey, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('fetchSingle', customPermission)) {
      return _config.emptyObject;
    }
    try {
      List<E> list = await fetchBehaviourValue(_config.cacheKeyEncoder(listKey),
              stream: _streamCollectionBuilder(listKey)) ??
          [];
      return list.firstWhere((e) => _config.hasKey(e, singleKey),
          orElse: () => _config.emptyObject);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'fetchSingle');
      return _config.emptyObject;
    }
  }

  /// Checks if a specific entity `E` exists within a collection identified by `listKey` and `singleKey`.
  ///
  /// This method asynchronously checks the existence of a document within a collection, handling permissions and errors.
  /// If permissions are denied or an error occurs, it returns `false`.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The key of the specific entity to check within the collection.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` indicating the existence of the entity.
  Future<bool> exist(
      {required LK listKey, required SK singleKey, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('exist', customPermission)) {
      return false;
    }
    try {
      return await _config.exist(_config.singlePath(listKey, singleKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'exist');
      return false;
    }
  }

  /// Caches all entities `E` within a collection identified by `listKey`.
  ///
  /// This method retrieves the cached list of entities `E` for a specific collection, handling permissions and errors.
  /// If permissions are denied or an error occurs, it returns an empty list.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A list of entities `E` if cached, otherwise an empty list.
  List<E> cacheAll({required LK listKey, CheckPermission? customPermission}) {
    if (_isPermissionDeni('cacheAll', customPermission)) {
      return [];
    }
    try {
      return getBehaviorValue(_config.cacheKeyEncoder(listKey)) ?? [];
    } catch (e) {
      AppLog.error('$e', repositoryName, 'cacheAll');
      return [];
    }
  }

  /// Caches a single entity `E` from a collection identified by `listKey` and filtered by `singleKey`.
  ///
  /// This method retrieves a single cached entity from a collection, handling permissions and errors.
  /// If permissions are denied or an error occurs, it returns a default empty entity.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The key of the specific entity to cache within the collection.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - An optional entity `E` if found in the cache, otherwise `null`.
  E? cacheSingle({required LK listKey, required SK singleKey, CheckPermission? customPermission}) {
    if (_isPermissionDeni('cacheSingle', customPermission)) {
      return _config.emptyObject;
    }
    try {
      return cacheAll(listKey: listKey)
          .firstWhere((e) => _config.hasKey(e, singleKey), orElse: () => _config.emptyObject);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'cacheSingle');
      return null;
    }
  }

  /// Sets a document in the collection with the given keys and entity data, handling permissions and errors.
  ///
  /// This method attempts to create or replace a document at the specified collection and document keys with the new entity data.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The document key of type `SK`.
  /// - [e]: The entity of type `E` to set at the specified key.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully set, otherwise `false`.
  Future<bool> set(
      {required LK listKey,
      required SK singleKey,
      required E e,
      CheckPermission? customPermission}) async {
    if (_isPermissionDeni('set', customPermission)) {
      return false;
    }
    try {
      return _config.setDocument(_config.singlePath(listKey, singleKey), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'set');
      return false;
    }
  }

  /// Updates an existing document with new data, handling permissions and errors.
  ///
  /// This method updates a document at the specified collection and document keys with the provided entity data.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The document key of type `SK`.
  /// - [e]: The updated entity of type `E` to store at the specified key.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully updated, otherwise `false`.
  Future<bool> update(
      {required LK listKey,
      required SK singleKey,
      required E e,
      CheckPermission? customPermission}) async {
    if (_isPermissionDeni('set', customPermission)) {
      return false;
    }
    try {
      return _config.updateDocument(_config.singlePath(listKey, singleKey), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'update');
      return false;
    }
  }

  /// Updates specific fields of a document at the given collection and document keys, handling permissions and errors.
  ///
  /// This method allows for partial updates to a document, modifying only the specified fields.
  /// It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The document key of type `SK`.
  /// - [data]: A map of fields and values that specify what should be updated.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the fields were successfully updated, otherwise `false`.
  Future<bool> updateValue(
      {required LK listKey,
      required SK singleKey,
      required Map<String, dynamic> data,
      CheckPermission? customPermission}) async {
    if (_isPermissionDeni('updateValue', customPermission)) {
      return false;
    }
    try {
      return _config.updateDocument(_config.singlePath(listKey, singleKey), data);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'updateValue');
      return false;
    }
  }

  /// Deletes a document at the specified collection and document keys, handling permissions and errors.
  ///
  /// This method attempts to delete a document at the given collection and document keys. It returns true if the operation is successful.
  ///
  /// Parameters:
  /// - [listKey]: The collection key of type `LK`.
  /// - [singleKey]: The document key of type `SK`.
  /// - [customPermission]: An optional parameter to provide custom permission logic.
  ///
  /// Returns:
  /// - A `Future<bool>` that completes with `true` if the document was successfully deleted, otherwise `false`.
  Future<bool> delete(
      {required LK listKey, required SK singleKey, CheckPermission? customPermission}) async {
    if (_isPermissionDeni('delete', customPermission)) {
      return false;
    }
    try {
      return _config.deleteDocument(_config.singlePath(listKey, singleKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'delete');
      return false;
    }
  }
}

/// Configuration class for document-based repository interfaces.
///
/// This class encapsulates all configuration needed to interact with a document-based data store. It includes
/// methods and properties for constructing paths, streaming, modifying, and querying documents, along with
/// permissions checking and data transformation functionalities.
///
/// Type parameters:
/// - `E`: The entity type that the repository manages.
/// - `SK`: The type used for identifying individual documents.
class RepositoryDocumentConfiguration<E, SK> {
  /// A function that generates a document path given a key of type `SK`.
  ///
  /// This function is responsible for defining how document paths are constructed based on their keys,
  /// which is essential for all operations that interact with the database.
  String Function(SK key) documentPath;

  /// A function that checks permissions for executing repository operations.
  ///
  /// This function should implement all necessary logic to verify if the current operation is allowed
  /// based on the application's authorization rules.
  CheckPermission checkPermission;

  /// A function that builds a stream of type `E` from a specified document path and a mapping function.
  ///
  /// This function should be able to create a `Stream<E>` that listens to the document changes at the given path,
  /// transforming the streamed data from a map (as it comes from the database) into an entity of type `E`.
  Stream<E> Function(String path, FromMap<E> fromMap) streamBuilder;

  /// A function that handles the setting (creating/updating) of a document at the specified path with the given data map.
  ///
  /// It returns a `Future<bool>` indicating the success of the operation.
  Future<bool> Function(String path, Map<String, dynamic> map) set;

  /// A function that handles updating an existing document at the specified path with the given data map.
  ///
  /// It returns a `Future<bool>` indicating the success of the operation.
  Future<bool> Function(String path, Map<String, dynamic> map) update;

  /// A function that deletes a document at a specified path.
  ///
  /// It returns a `Future<bool>` indicating the success of the deletion.
  Future<bool> Function(String path) delete;

  /// A function that checks the existence of a document at a specified path.
  ///
  /// It returns a `Future<bool>` indicating whether the document exists.
  Future<bool> Function(String path) exist;

  /// An object representing an empty or initial state of type `E`.
  ///
  /// This is typically used as a return value when no valid data could be fetched or as an initial state before any data is loaded.
  E emptyObject;

  /// A function that transforms a map into an entity of type `E`.
  ///
  /// This is crucial for converting the raw data retrieved from the database into a usable entity object.
  FromMap<E> fromMap;

  /// A function that transforms an entity of type `E` into a map.
  ///
  /// This allows the entity to be stored in the database in a structured format.
  ToMap<E> toMap;

  /// Constructor for [RepositoryDocumentConfiguration] requiring all fields to be initialized.
  ///
  /// Parameters:
  /// - `documentPath`: Function to construct document paths.
  /// - `checkPermission`: Function to check operation permissions.
  /// - `streamBuilder`: Function to build streams of data.
  /// - `set`: Function to create or update documents.
  /// - `update`: Function to update documents.
  /// - `delete`: Function to delete documents.
  /// - `exist`: Function to check document existence.
  /// - `emptyObject`: An initial or empty state of type `E`.
  /// - `fromMap`: Function to deserialize data from map format.
  /// - `toMap`: Function to serialize entities to map format.
  RepositoryDocumentConfiguration({
    required this.documentPath,
    required this.checkPermission,
    required this.streamBuilder,
    required this.set,
    required this.update,
    required this.delete,
    required this.exist,
    required this.emptyObject,
    required this.fromMap,
    required this.toMap,
  });
}

/// Configuration class for collection-based repository interfaces.
///
/// This class encapsulates all necessary configurations to interact with a collection-based data store. It defines
/// methods and properties for constructing paths, streaming collections, and performing CRUD operations on documents,
/// as well as handling permissions and transforming data between maps and entity objects.
///
/// Type parameters:
/// - `E`: The entity type that the repository manages within collections.
/// - `LK`: The type used to determine the path of a collection.
/// - `SK`: The type used for identifying individual documents within a collection.
/// - `BK`: The type used for caching and keying lists of documents.
class RepositoryCollectionConfiguration<E, LK, SK, BK> {
  /// A function that generates a collection path given a key of type `LK`.
  ///
  /// This function is crucial for defining how collection paths are constructed, which underpins all operations
  /// that interact with collections in the database.
  String Function(LK listKey) collectionPath;

  /// A function that checks permissions for executing repository operations.
  ///
  /// This function must implement all necessary logic to verify if an operation is allowed based on
  /// the application's authorization rules.
  CheckPermission checkPermission;

  /// A function that generates a document path within a collection given a collection key of type `LK` and
  /// a document key of type `SK`.
  ///
  /// This function is used for operations that need to interact with specific documents within a collection.
  String Function(LK listKey, SK singleKey) singlePath;

  /// A function that builds a stream of a list of entities `E` from a specified collection path and a mapping function.
  ///
  /// This function should be capable of creating a `Stream<List<E>>` that listens to changes within a collection
  /// at the given path, transforming the streamed data from a map (as it comes from the database) into entities of type `E`.
  Stream<List<E>> Function(String path, FromMap<E> fromMap) streamCollectionBuilder;

  /// A function that handles the setting (creating/updating) of a document at the specified path within a collection with the given data map.
  ///
  /// It returns a `Future<bool>` indicating the success of the operation.
  Future<bool> Function(String path, Map<String, dynamic> map) setDocument;

  /// A function that handles updating an existing document at the specified path within a collection with the given data map.
  ///
  /// It returns a `Future<bool>` indicating the success of the operation.
  Future<bool> Function(String path, Map<String, dynamic> map) updateDocument;

  /// A function that deletes a document at a specified path within a collection.
  ///
  /// It returns a `Future<bool>` indicating the success of the deletion.
  Future<bool> Function(String path) deleteDocument;

  /// A function that checks the existence of a document at a specified path within a collection.
  ///
  /// It returns a `Future<bool>` indicating whether the document exists.
  Future<bool> Function(String path) exist;

  /// A function that encodes a collection key of type `LK` to a cache key of type `BK`.
  ///
  /// This function is used to generate unique cache keys for caching collections or lists of documents.
  BK Function(LK listKey) cacheKeyEncoder;

  /// A function that determines if an entity `E` matches a specified document key `SK`.
  ///
  /// This function is used for filtering and identifying specific documents within a list of entities.
  bool Function(E e, SK key) hasKey;

  /// An object representing an empty or initial state of type `E`.
  ///
  /// This is typically used as a return value when no valid data could be fetched or as an initial state before any data is loaded.
  E emptyObject;

  /// A function that transforms a map into an entity of type `E`.
  ///
  /// This function is essential for converting the raw data retrieved from the database into a usable entity object.
  FromMap<E> fromMap;

  /// A function that transforms an entity of type `E` into a map.
  ///
  /// This function allows the entity to be stored in the database in a structured format.
  ToMap<E> toMap;

  /// Constructor for [RepositoryCollectionConfiguration] requiring all fields to be initialized.
  ///
  /// Parameters:
  /// - `collectionPath`: Function to construct collection paths.
  /// - `checkPermission`: Function to check operation permissions.
  /// - `singlePath`: Function to construct individual document paths within a collection.
  /// - `streamCollectionBuilder`: Function to build streams of data for collections.
  /// - `setDocument`: Function to create or update documents within a collection.
  /// - `updateDocument`: Function to update documents within a collection.
  /// - `deleteDocument`: Function to delete documents within a collection.
  /// - `exist`: Function to check document existence.
  /// - `cacheKeyEncoder`: Function to encode collection keys for caching.
  /// - `hasKey`: Function to determine if an entity matches a specific key.
  /// - `emptyObject`: An initial or empty state of type `E`.
  /// - `fromMap`: Function to deserialize data from map format.
  /// - `toMap`: Function to serialize entities to map format.
  RepositoryCollectionConfiguration({
    required this.collectionPath,
    required this.checkPermission,
    required this.singlePath,
    required this.streamCollectionBuilder,
    required this.setDocument,
    required this.updateDocument,
    required this.deleteDocument,
    required this.exist,
    required this.cacheKeyEncoder,
    required this.hasKey,
    required this.emptyObject,
    required this.fromMap,
    required this.toMap,
  });
}
