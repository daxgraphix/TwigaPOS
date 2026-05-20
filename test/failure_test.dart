import 'package:flutter_test/flutter_test.dart';
import 'package:twigapos/core/error/failure.dart';

void main() {
  group('Failure', () {
    test('CacheFailure should have correct message', () {
      const failure = CacheFailure('Cache error');
      expect(failure.message, 'Cache error');
      expect(failure.props, [failure.message]);
    });

    test('DatabaseFailure should have correct message', () {
      const failure = DatabaseFailure('Database error');
      expect(failure.message, 'Database error');
    });

    test('NetworkFailure should have correct message', () {
      const failure = NetworkFailure('Network error');
      expect(failure.message, 'Network error');
    });

    test('AuthFailure should have correct message', () {
      const failure = AuthFailure('Auth error');
      expect(failure.message, 'Auth error');
    });

    test('ValidationFailure should have correct message and errors', () {
      const failure = ValidationFailure(
        'Validation error',
        errors: {'field': 'required'},
      );
      expect(failure.message, 'Validation error');
      expect(failure.errors, {'field': 'required'});
    });

    test('Failure equality should work correctly', () {
      const failure1 = CacheFailure('Same message');
      const failure2 = CacheFailure('Same message');
      const failure3 = CacheFailure('Different message');

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });

  group('FailureExtensions', () {
    test('userFriendlyMessage should return correct message for NetworkFailure', () {
      const failure = NetworkFailure('Network error');
      expect(
        failure.userFriendlyMessage,
        'No internet connection. Please check your network and try again.',
      );
    });

    test('userFriendlyMessage should return correct message for AuthFailure', () {
      const failure = AuthFailure('Auth error');
      expect(
        failure.userFriendlyMessage,
        'Authentication failed. Please log in again.',
      );
    });

    test('userFriendlyMessage should return correct message for PermissionFailure', () {
      const failure = PermissionFailure('Permission error');
      expect(
        failure.userFriendlyMessage,
        "You don't have permission to perform this action.",
      );
    });

    test('userFriendlyMessage should return original message for other failures', () {
      const failure = DatabaseFailure('Database connection lost');
      expect(failure.userFriendlyMessage, 'Database connection lost');
    });
  });
}
