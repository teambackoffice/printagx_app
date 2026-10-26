import 'package:flutter/foundation.dart';
import 'package:printagx_app/data/models/user_session.dart';
import 'package:printagx_app/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  AuthViewModel(this._repository);

  UserSession? _session;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get error => _error;
  bool get isLoggedIn => _session != null;
  String get fullName => _session?.fullName ?? 'User';
  String get employeeId => _session?.employeeId ?? '';

  Future<void> restoreSession() async {
    final session = await _repository.restoreSession();
    if (session == _session) return;
    _session = session;
    notifyListeners();
  }

  /// Returns true when the user is signed in.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _repository.login(username, password);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _error == null;
  }

  /// Returns true when the user has been signed out.
  Future<bool> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    var success = true;
    try {
      await _repository.logout();
      _session = null;
    } catch (_) {
      success = false;
    }

    _isLoggingOut = false;
    notifyListeners();
    return success;
  }
}
