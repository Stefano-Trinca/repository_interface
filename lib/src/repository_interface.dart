import 'package:applog/applog.dart';

import 'behavior_mixin.dart';

typedef FromMap<E> = E Function(Map<String, dynamic> data, String? key);
typedef ToMap<E> = Map<String, dynamic> Function(E e);
typedef CheckPermission = bool Function();


abstract class RepositoryDocumentInterface<E, SK> with BehaviorMixin<E> {
  String get repositoryName;

  RepositoryDocumentConfiguration<E, SK> get configuration;

  RepositoryDocumentConfiguration<E, SK> get _config => configuration;

  //
  //
  //
  //
  //

  Stream<E> _streamBuilder(SK key) =>
      _config.streamBuilder(_config.documentPath(key), _config.fromMap);

  Stream<E> stream({required SK key}) {
    checkNetworkConfiguration();
    try {
      return _streamBuilder(key);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'stream');
      return const Stream.empty();
    }
  }

  Future<E> fetch({required SK key}) async {
    checkNetworkConfiguration();
    try {
      return await fetchBehaviorValue(stream: _streamBuilder(key)) ?? _config.emptyObject;
    } catch (e) {
      AppLog.error('$e', repositoryName, 'fetch');
      return _config.emptyObject;
    }
  }

  E? cache({required SK key}) {
    try {
      return getBehaviorValue();
    } catch (e) {
      AppLog.error('$e', repositoryName, 'cache');
    }
    return null;
  }

  Future<bool> set({required SK key, required E e}) async {
    checkNetworkConfiguration();
    try {
      return _config.set(_config.documentPath(key), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'set');
      return false;
    }
  }

  Future<bool> update({required SK key, required E e}) async {
    checkNetworkConfiguration();
    try {
      return _config.update(_config.documentPath(key), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'update');
      return false;
    }
  }

  Future<bool> updateValue({required SK key, required Map<String, dynamic> data}) async {
    checkNetworkConfiguration();
    try {
      return _config.update(_config.documentPath(key), data);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'updateValue');
      return false;
    }
  }

  Future<bool> delete({required SK key}) async {
    checkNetworkConfiguration();
    try {
      return _config.delete(_config.documentPath(key));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'delete');
      return false;
    }
  }

  Future<bool> exist({required SK singleKey}) async {
    try {
      checkNetworkConfiguration();
      return await _config.exist(_config.documentPath(singleKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'exist');
      return false;
    }
  }
}

/// Repository Collection Interface
///
/// E = Object Type
///
/// LK = Key type for determinate the collection path
///
/// SK = Key for the single object path
///
/// BK = Key type for determinate the cache list
abstract class RepositoryCollectionInterface<E, LK, SK, BK>
    with BehaviorListMixin<BK, List<E>> {
  String get repositoryName;

  RepositoryCollectionConfiguration<E, LK, SK, BK> get configuration;

  RepositoryCollectionConfiguration<E, LK, SK, BK> get _config => configuration;

  //
  //
  //
  //

  Stream<List<E>> _streamCollectionBuilder(LK listKey) =>
      _config.streamCollectionBuilder(_config.collectionPath(listKey), _config.fromMap);

  bool _isPermissionDeni(String method,CheckPermission? customPermissions){
    if(!(customPermissions?.call() ?? _config.checkPermission.call())){
      AppLog.error('Permission Deni', repositoryName, method);
      return true;
    }
    return false;
  }


  Stream<List<E>> streamAll({required LK listKey, CheckPermission? customPermission}) {
    if(_isPermissionDeni('streamAll', customPermission)){
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

  Stream<E> streamSingle({required LK listKey, required SK singleKey,CheckPermission? customPermission}) {
    if(_isPermissionDeni('streamSingle', customPermission)){
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

  Future<List<E>> fetchAll({required LK listKey,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('fetchAll', customPermission)){
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

  Future<E> fetchSingle({required LK listKey, required SK singleKey,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('fetchSingle', customPermission)){
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

  Future<bool> exist({required LK listKey, required SK singleKey,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('exist', customPermission)){
      return false;
    }
    try {
      return await _config.exist(_config.singlePath(listKey, singleKey));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'exist');
      return false;
    }
  }

  List<E> cacheAll({required LK listKey,CheckPermission? customPermission}) {
    if(_isPermissionDeni('cacheAll', customPermission)){
      return [];
    }
    try {
      return getBehaviorValue(_config.cacheKeyEncoder(listKey)) ?? [];
    } catch (e) {
      AppLog.error('$e', repositoryName, 'cacheAll');
      return [];
    }
  }

  E? cacheSingle({required LK listKey, required SK singleKey,CheckPermission? customPermission}) {
    if(_isPermissionDeni('cacheSingle', customPermission)){
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

  Future<bool> set({required LK listKey, required SK singleKey, required E e,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('set', customPermission)){
      return false;
    }
    try {
      return _config.setDocument(_config.singlePath(listKey, singleKey), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'set');
      return false;
    }
  }

  Future<bool> update({required LK listKey, required SK singleKey, required E e,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('set', customPermission)){
      return false;
    }
    try {
      return _config.updateDocument(_config.singlePath(listKey, singleKey), _config.toMap(e));
    } catch (e) {
      AppLog.error('$e', repositoryName, 'update');
      return false;
    }
  }

  Future<bool> updateValue(
      {required LK listKey, required SK singleKey, required Map<String, dynamic> data,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('updateValue', customPermission)){
      return false;
    }
    try {
      return _config.updateDocument(_config.singlePath(listKey, singleKey), data);
    } catch (e) {
      AppLog.error('$e', repositoryName, 'updateValue');
      return false;
    }
  }

  Future<bool> delete({required LK listKey, required SK singleKey,CheckPermission? customPermission}) async {
    if(_isPermissionDeni('delete', customPermission)){
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

/// Repository Document Interface Configuration
/// this is the configuration for the Document
///
/// E = Object Type
///
/// SK = Key for the single object path
class RepositoryDocumentConfiguration<E, SK> {
  String Function(SK key) documentPath;

  /// Check permission for call the function
  CheckPermission checkPermission;

  Stream<E> Function(String path, FromMap<E> fromMap) streamBuilder;

  Future<bool> Function(String path, Map<String, dynamic> map) set;

  Future<bool> Function(String path, Map<String, dynamic> map) update;

  Future<bool> Function(String path) delete;

  Future<bool> Function(String path) exist;

  E emptyObject;

  /// Object from map
  FromMap<E> fromMap;

  /// Object to Map
  ToMap<E> toMap;

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

/// Repository Collection Interface Configuration
/// this is the configuration for the DataCollection
///
/// E = Object Type
///
/// LK = Key type for determinate the collection path
///
/// SK = Key for the single object path
///
/// BK = Key type for determinate the cache list
class RepositoryCollectionConfiguration<E, LK, SK, BK> {
  String Function(LK listKey) collectionPath;

  /// Check permission for call the function
  CheckPermission checkPermission;

  String Function(LK listKey, SK singleKey) singlePath;

  Stream<List<E>> Function(String path, FromMap<E> fromMap) streamCollectionBuilder;

  Future<bool> Function(String path, Map<String, dynamic> map) setDocument;

  Future<bool> Function(String path, Map<String, dynamic> map) updateDocument;

  Future<bool> Function(String path) deleteDocument;

  Future<bool> Function(String path) exist;

  /// Encoder for the Cache List key
  BK Function(LK listKey) cacheKeyEncoder;

  /// Determinazione dell'oggetto dalla chiave
  bool Function(E e, SK key) hasKey;

  E emptyObject;

  /// Object from map
  FromMap<E> fromMap;

  /// Object to Map
  ToMap<E> toMap;

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
