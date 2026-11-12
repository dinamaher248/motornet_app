/// Lightweight functional Either without external packages.
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    final self = this;
    if (self is Left<L, R>) return onLeft(self.value);
    return onRight((self as Right<L, R>).value);
  }

  R getOrElse(R Function(L left) orElse) {
    return fold(orElse, (r) => r);
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}
