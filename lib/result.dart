import 'package:sqflite/sqflite.dart';

class Result<T> {
  Result.success(T this.success) : error = null, errorMessage = null;
  Result.error(ErrorType this.error, String this.errorMessage) : success = null;

  static Future<Result<T>> from<T>(Future<T> Function() fn) async {
    try {
      return Result.success(await fn());
    } on DatabaseException catch (e) {
      return Result.error(
        e.isUniqueConstraintError()
            ? ErrorType.uniqueConstraint
            : ErrorType.unknown,
        e.toString(),
      );
    }
  }

  /// not null if success
  final T? success;

  /// not null if error
  final ErrorType? error;

  /// not null if error
  final String? errorMessage;

  bool get isSuccess => success != null;
  bool get isError => error != null;
}

enum ErrorType {
  uniqueConstraint,
  invalidJson,
  invalidUtf8,
  invalidGearModel,
  unknown;

  bool get isUniqueViolation => this == ErrorType.uniqueConstraint;
}
