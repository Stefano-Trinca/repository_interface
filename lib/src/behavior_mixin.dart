import 'package:rxdart/rxdart.dart';

/// A mixin to add behavior subject stream functionality to a class.
///
/// This mixin allows the class to manage state through a BehaviorSubject, which is a special
/// StreamController that captures the latest item that has been added to the controller.
///
/// Type parameter:
/// - `E`: The type of object stored in the BehaviorSubject.
abstract mixin class BehaviorMixin<E> {
  BehaviorSubject<E>? behaviour;

  /// Retrieves the stream of the BehaviorSubject, or initializes it with an optional [stream].
  ///
  /// If the BehaviorSubject [behaviour] is not yet created and a [stream] is provided, this method
  /// initializes the BehaviorSubject with the events from [stream]. If no [stream] is provided,
  /// it returns an empty stream.
  ///
  /// If the BehaviorSubject [behaviour] already exists but is closed, this method will return an empty stream.
  /// Otherwise, it returns the current stream of the BehaviorSubject.
  ///
  /// Parameters:
  /// - [stream] (optional): A stream of type `E` used to initialize the BehaviorSubject if it is not already initialized.
  ///
  /// Returns:
  /// - A stream of type `E` representing the current or new BehaviorSubject stream, or an empty stream if
  ///   the behavior subject cannot be created or is closed.
  Stream<E> getBehaviourStream({
    Stream<E>? stream,
  }) {
    /// Behaviour not created
    if (behaviour == null) {
      if (stream != null) {
        BehaviorSubject<E> nBehavior = BehaviorSubject<E>();
        stream.listen((event) {
          nBehavior.add(event);
        });
        behaviour = nBehavior;
        return nBehavior.stream;
      } else {
        return const Stream.empty();
      }
    } else {
      if (behaviour!.isClosed) {
        return const Stream.empty();
      }
      return behaviour!.stream;
    }
  }

  /// Fetches the latest value of the BehaviorSubject asynchronously, or initializes it with an optional [stream].
  ///
  /// If the BehaviorSubject [behaviour] is not yet created and a [stream] is provided, this method initializes
  /// the BehaviorSubject and returns the first event of the stream as the future value. If no [stream] is provided,
  /// it returns null.
  ///
  /// If the BehaviorSubject [behaviour] already exists, this method returns the latest value or null if the BehaviorSubject
  /// is closed.
  ///
  /// Parameters:
  /// - [stream] (optional): A stream of type `E` used to initialize the BehaviorSubject if it is not already initialized.
  ///
  /// Returns:
  /// - A future containing the latest value of `E` from the BehaviorSubject, or null if it can't be fetched.
  Future<E?> fetchBehaviorValue({Stream<E>? stream}) async {
    /// Behavior not created
    if (behaviour == null) {
      if (stream != null) {
        BehaviorSubject<E> nBehavior = BehaviorSubject<E>();
        stream.listen((event) {
          nBehavior.add(event);
        });
        behaviour = nBehavior;
        return await nBehavior.first;
      } else {
        return null;
      }
    } else {
      if (behaviour!.isClosed) {
        return null;
      }
      return behaviour!.value;
    }
  }

  /// Retrieves the current value from the BehaviorSubject, if available, without throwing.
  ///
  /// Returns:
  /// - The current value of `E` held in the BehaviorSubject, or null if no value is present or if it is closed.
  E? getBehaviorValue() => behaviour?.valueOrNull;

  /// Updates the BehaviorSubject with a new value [e] if the BehaviorSubject is not closed and has a value.
  ///
  /// Parameters:
  /// - [e]: The new value to add to the BehaviorSubject.
  ///
  /// This method will add the value [e] to the stream, making it the latest value available to listeners.
  void updateBehavior(E e) {
    if (behaviour != null && behaviour!.hasValue) {
      behaviour!.add(e);
    }
  }
}

/// A mixin for managing a list of keyed `BehaviorSubject` objects.
///
/// This mixin provides methods to manipulate and access multiple `BehaviorSubject`s, each associated with a unique key.
/// It is particularly useful for maintaining stateful streams in applications that require dynamic and keyed state management.
///
/// Type parameters:
/// - `T`: The type used as the key for each BehaviorSubject.
/// - `E`: The type of object stored in each BehaviorSubject.
abstract mixin class BehaviorListMixin<T, E> {
  List<BehaviorObject<T, E>> behaviours = [];

  /// Abstract method to compare two keys.
  ///
  /// Implement this method to specify how keys should be compared for equality.
  /// This is necessary for correctly identifying the corresponding `BehaviorSubject` for a given key.
  ///
  /// Parameters:
  /// - [keyA]: The first key to compare.
  /// - [keyB]: The second key to compare.
  ///
  /// Returns:
  /// - `true` if the keys are considered equal, otherwise `false`.
  bool compareBehaviourKey(T keyA, T keyB);

  /// Adds a new `BehaviorObject` to the list.
  ///
  /// This method should be implemented to handle the addition of new behaviors to the list.
  /// - [data]: The `BehaviorObject` to add.
  void addBehaviour(BehaviorObject<T, E> data) {}

  /// Retrieves the stream of a `BehaviorSubject` associated with the given key or initializes it with an optional [stream].
  ///
  /// If no `BehaviorSubject` is found for the specified [key] and a [stream] is provided, this method
  /// initializes a new `BehaviorSubject`, subscribes it to the provided [stream], and returns the BehaviorSubject's stream.
  /// If no [stream] is provided and no existing subject is found, it returns an empty stream.
  ///
  /// Parameters:
  /// - [key]: The key associated with the `BehaviorSubject` to retrieve.
  /// - [stream] (optional): A stream of type `E` used to initialize the `BehaviorSubject` if it is not already initialized.
  ///
  /// Returns:
  /// - A stream of type `E` representing the current or new `BehaviorSubject` stream, or an empty stream if
  ///   the `BehaviorSubject` cannot be created or found.
  Stream<E> getBehaviourStream(
    T key, {
    Stream<E>? stream,
  }) {
    int idx = behaviours.indexWhere((e) => compareBehaviourKey(e.key, key));
    if (idx == -1) {
      if (stream != null) {
        BehaviorSubject<E> nBehavior = BehaviorSubject<E>();
        stream.listen((event) {
          nBehavior.add(event);
        });
        _addBehavior(key, nBehavior);
        return nBehavior.stream;
      } else {
        return const Stream.empty();
      }
    } else {
      return behaviours[idx].behaviour.stream;
    }
  }

  /// Asynchronously fetches the latest value of the `BehaviorSubject` associated with the given key, or initializes it.
  ///
  /// If no `BehaviorSubject` is found for the specified [key] and a [stream] is provided, this method initializes
  /// a new `BehaviorSubject`, subscribes it to the provided [stream], waits for the first event, and returns it.
  /// If no `BehaviorSubject` exists and no [stream] is provided, or if the `BehaviorSubject` is found but has no value,
  /// this method returns null.
  ///
  /// Parameters:
  /// - [key]: The key associated with the `BehaviorSubject` to retrieve or initialize.
  /// - [stream] (optional): A stream of type `E` used to initialize the `BehaviorSubject` if it is not already initialized.
  ///
  /// Returns:
  /// - A future containing the latest value of `E` from the `BehaviorSubject`, or null if it can't be fetched.
  Future<E?> fetchBehaviourValue(
    T key, {
    Stream<E>? stream,
  }) async {
    int idx = behaviours.indexWhere((e) => compareBehaviourKey(e.key, key));
    if (idx == -1) {
      if (stream != null) {
        BehaviorSubject<E> nBehavior = BehaviorSubject<E>();
        stream.listen((event) {
          nBehavior.add(event);
        });
        _addBehavior(key, nBehavior);
        return await nBehavior.stream.first;
      } else {
        return null;
      }
    } else {
      if (behaviours[idx].behaviour.hasValue) {
        return behaviours[idx].behaviour.valueOrNull;
      }
      return behaviours[idx].behaviour.first;
    }
  }

  /// Retrieves the current value from the `BehaviorSubject` associated with the specified key, if available.
  ///
  /// Parameters:
  /// - [key]: The key associated with the `BehaviorSubject` to retrieve the value from.
  ///
  /// Returns:
  /// - The current value of `E` held in the `BehaviorSubject`, or null if no value is present or if the subject is not found.
  E? getBehaviorValue(T key) {
    int idx = behaviours.indexWhere((e) => compareBehaviourKey(e.key, key));
    if (idx != -1) {
      return behaviours[idx].behaviour.valueOrNull;
    } else {
      return null;
    }
  }

  /// Internal method to add a new `BehaviorSubject` associated with a given key to the list of behaviors.
  ///
  /// Parameters:
  /// - [key]: The key to associate with the new `BehaviorSubject`.
  /// - [nBehavior]: The new `BehaviorSubject` to add.
  void _addBehavior(T key, BehaviorSubject<E> nBehavior) {
    //TODO: add limit to behavior quantity
    behaviours.add(BehaviorObject<T, E>(key: key, behaviour: nBehavior));
  }
}

/// Represents a key-value pair for managing behavior subjects within the `BehaviorListMixin`.
///
/// Parameters:
/// - [key]: The unique key associated with the `BehaviorSubject`.
/// - [behaviour]: The `BehaviorSubject` storing values of type `E`.
class BehaviorObject<T, E> {
  final T key;
  final BehaviorSubject<E> behaviour;

  const BehaviorObject({
    required this.key,
    required this.behaviour,
  });
}
