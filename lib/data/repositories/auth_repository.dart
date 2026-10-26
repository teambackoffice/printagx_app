import 'package:printagx_app/data/mock/mock_data.dart';
import 'package:printagx_app/data/models/user_session.dart';

abstract class AuthRepository {
  /// Returns the stored session, or null if the user is signed out.
  Future<UserSession?> restoreSession();

  /// Throws an [AuthException] when the credentials are rejected.
  Future<UserSession> login(String username, String password);

  Future<void> logout();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Local-only implementation: accepts any non-empty credentials.
class MockAuthRepository implements AuthRepository {
  UserSession? _session;

  @override
  Future<UserSession?> restoreSession() async => _session;

  @override
  Future<UserSession> login(String username, String password) async {
    await Future.delayed(mockDelay);
    if (username.isEmpty || password.isEmpty) {
      throw const AuthException('Please enter username and password');
    }
    final name = username.split('@').first;
    return _session = UserSession(
      fullName: name.isEmpty
          ? 'User'
          : name[0].toUpperCase() + name.substring(1),
      employeeId: 'EMP-0001',
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(mockDelay);
    _session = null;
  }
}
