sealed class Either<L, R> {
  const Either();
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    final self = this;
    if (self is Left<L, R>) return onLeft(self.value);
    return onRight((self as Right<L, R>).value);
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

class Unit {
  const Unit();
}

const unit = Unit();
