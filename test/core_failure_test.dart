import 'package:flutter_test/flutter_test.dart';
import 'package:twigapos/core/error/failure.dart';

void main() {
  group('Failure Classes', () {
    test('CacheFailure stores message correctly', () {
      const failure = CacheFailure('Test cache error');
      expect(failure.message, equals('Test cache error'));
    });

    test('DatabaseFailure stores message correctly', () {
      const failure = DatabaseFailure('Test database error');
      expect(failure.message, equals('Test database error'));
    });

    test('NetworkFailure stores message correctly', () {
      const failure = NetworkFailure('No connection');
      expect(failure.message, equals('No connection'));
    });

    test('AuthFailure stores message correctly', () {
      const failure = AuthFailure('Invalid credentials');
      expect(failure.message, equals('Invalid credentials'));
    });

    test('ValidationFailure stores message and errors', () {
      const failure = ValidationFailure(
        'Invalid input',
        errors: {'email': 'required'},
      );
      expect(failure.message, equals('Invalid input'));
      expect(failure.errors, equals({'email': 'required'}));
    });

    test('Failure instances with same message are equal', () {
      const f1 = CacheFailure('Same');
      const f2 = CacheFailure('Same');
      expect(f1, equals(f2));
    });

    test('Failure instances with different messages are not equal', () {
      const f1 = CacheFailure('First');
      const f2 = CacheFailure('Second');
      expect(f1, isNot(equals(f2)));
    });
  });

  group('Failure userFriendlyMessage', () {
    test('NetworkFailure returns friendly message', () {
      const failure = NetworkFailure('error');
      expect(
        failure.userFriendlyMessage,
        contains('internet connection'),
      );
    });

    test('AuthFailure returns friendly message', () {
      const failure = AuthFailure('error');
      expect(
        failure.userFriendlyMessage,
        contains('Authentication failed'),
      );
    });

    test('PermissionFailure returns friendly message', () {
      const failure = PermissionFailure('error');
      expect(
        failure.userFriendlyMessage,
        contains('permission'),
      );
    });

    test('Other failures return original message', () {
      const failure = DatabaseFailure('Custom database message');
      expect(failure.userFriendlyMessage, equals('Custom database message'));
    });
  });
}
