# Repository Interface

This Dart package provides a robust interface for implementing repository patterns in Dart and Flutter applications. It abstracts common CRUD operations into a customizable interface that can be adapted to various data storage solutions, such as Firebase Firestore.

## Features

- **Customizable Repository Interfaces:** Define your repository interactions with customizable document and collection configurations.
- **Streamlined Data Handling:** Use streams to handle real-time data updates and maintain synchronization with your data source.
- **Type Safety:** Leverage Dart's strong typing to ensure your data handling is clear and error-free.

## Installation

To use this package, add the following dependency to your project's `pubspec.yaml`:

```yaml
repository_interface:
  git:
    url: https://github.com/Stefano-Trinca/repository_interface.git
    ref: 0.0.3
```

## Usage Example

Below is an example of how to implement a `UserDataRepository` using the `RepositoryDocumentInterface`. This example integrates with Firebase Firestore to manage user data:

```dart
class UserDataRepository extends RepositoryDocumentInterface<UserData, String>
    with FirebaseCloudfirestoreImpl, NetworkManagerInterface {
  @override
  String get repositoryName => 'UserDataRepository';

  @override
  RepositoryDocumentConfiguration<UserData, String> get configuration =>
      RepositoryDocumentConfiguration(
        documentPath: (key) => pathCloudfirestore.userdata(netconfig.uid),
        streamBuilder: (path, fromMap) => serviceCloudfirestore.streamDocument(
          path: path,
          builder: fromMap,
          onNull: const UserData.empty(),
        ),
        set: (path, map) => serviceCloudfirestore.setDocument(path: path, data: map),
        update: (path, map) => serviceCloudfirestore.updateDocument(path: path, data: map),
        delete: (path) => serviceCloudfirestore.deleteDocument(path: path),
        exist: (path) => serviceCloudfirestore.exist(path: path),
        emptyObject: const UserData.empty(),
        fromMap: (data, key) => UserDataModel.fromMap(data).toEntity(),
        toMap: (e) => UserDataModel.fromEntity(e).toMap(),
      );
}
```

This setup demonstrates configuring a repository to interact with Firestore, where `UserData` is a domain model representing user data.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
