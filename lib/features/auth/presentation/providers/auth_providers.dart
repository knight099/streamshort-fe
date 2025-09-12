import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/providers.dart';

// Auth State
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthAuthenticated({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthInitial());

  Future<void> sendOtp(String phone, {String countryCode = '+91'}) async {
    try {
      state = const AuthLoading();
      final response = await _authRepository.sendOtp(phone, countryCode: countryCode);
      
      // Store request ID for verification
      // You can use shared preferences or secure storage here
      
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String otp, String requestId) async {
    try {
      state = const AuthLoading();
      final response = await _authRepository.verifyOtp(phone, otp, requestId);
      
      // Store tokens securely
      // You can use secure storage here
      
      state = AuthAuthenticated(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> refreshToken(String refreshToken) async {
    try {
      state = const AuthLoading();
      final response = await _authRepository.refreshToken(refreshToken);
      
      // Update stored tokens
      
      state = AuthAuthenticated(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } catch (e) {
      state = AuthError(e.toString());
      // If refresh fails, user needs to login again
      state = const AuthUnauthenticated();
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AuthUnauthenticated();
    } catch (e) {
      // Even if logout fails, clear local state
      state = const AuthUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> updateUserRole(String newRole) async {
    try {
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        final updatedUser = User(
          id: currentState.user.id,
          phone: currentState.user.phone,
          displayName: currentState.user.displayName,
          avatarUrl: currentState.user.avatarUrl,
          role: newRole,
          createdAt: currentState.user.createdAt,
          lastLoginAt: currentState.user.lastLoginAt,
        );
        
        // Update the stored user data with the new role
        await _authRepository.updateStoredUserRole(newRole);
        
        state = AuthAuthenticated(
          user: updatedUser,
          accessToken: currentState.accessToken,
          refreshToken: currentState.refreshToken,
        );
      }
    } catch (e) {
      // Handle error if needed
      print('Error updating user role: $e');
    }
  }

  // Restore authentication from storage
  Future<void> restoreAuth() async {
    try {
      state = const AuthLoading();
      final storedAuth = await _authRepository.loadStoredAuth();
      
      if (storedAuth != null) {
        state = storedAuth;
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }
}

// Providers
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthLoading;
});

final authUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated;
});

final accessTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.accessToken;
  }
  return null;
});
