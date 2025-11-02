/// A sealed class representing a value that can be one of two types.
///
/// This is often used to represent a value that can be either a success or a failure.
/// By convention, `L` is the error type and `R` is the success type.
sealed class DatumEither<L, R> {
  const DatumEither();

  /// Returns `true` if this is a `Failure`.
  bool isFailure() => this is Failure<L, R>;

  /// Returns `true` if this is a `Success`.
  bool isSuccess() => this is Success<L, R>;

  /// Folds the `Either` into a single value.
  ///
  /// If this is a `Failure`, the `onFailure` function is called with the value.
  /// If this is a `Success`, the `onSuccess` function is called with the value.
  T fold<T>(T Function(L l) onFailure, T Function(R r) onSuccess);

  /// Performs an action on the success value.
  void onSuccess(void Function(R r) onSuccess) {
    if (this is Success<L, R>) {
      onSuccess((this as Success<L, R>).value);
    }
  }

  /// Performs an action on the failure value.
  void onFailure(void Function(L l) onFailure) {
    if (this is Failure<L, R>) {
      onFailure((this as Failure<L, R>).value);
    }
  }

  /// Returns the success value, or throws an exception if this is a `Failure`.
  R getSuccess() {
    if (this is Success<L, R>) {
      return (this as Success<L, R>).value;
    } else {
      throw StateError('Cannot get success value from a Failure.');
    }
  }

  /// Returns the failure value, or throws an exception if this is a `Success`.
  L getError() {
    if (this is Failure<L, R>) {
      return (this as Failure<L, R>).value;
    } else {
      throw StateError('Cannot get error value from a Success.');
    }
  }
}

/// Represents the failure case of an `Either`.
class Failure<L, R> extends DatumEither<L, R> {
  const Failure(this.value);

  final L value;

  @override
  T fold<T>(T Function(L l) onFailure, T Function(R r) onSuccess) => onFailure(value);
}

/// Represents the success case of an `Either`.
class Success<L, R> extends DatumEither<L, R> {
  const Success(this.value);

  final R value;

  @override
  T fold<T>(T Function(L l) onFailure, T Function(R r) onSuccess) => onSuccess(value);
}
