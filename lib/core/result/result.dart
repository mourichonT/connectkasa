/// Résultat d'une opération pouvant échouer (typiquement un appel
/// Firestore/Auth), sans dépendre d'exceptions non typées ni de valeurs
/// null ambiguës (succès vide vs échec silencieux).
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Object error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Valeur en cas de succès, `null` sinon.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// Erreur en cas d'échec, `null` sinon.
  Object? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Applique `onSuccess` ou `onFailure` selon le cas, et retourne le
  /// résultat de celui qui a été appelé.
  R when<R>({
    required R Function(T value) success,
    required R Function(Object error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Transforme la valeur en cas de succès, propage l'échec tel quel.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Result.success(transform(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final Object error;
  const Failure(this.error);
}
