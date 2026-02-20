import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthState {
  final User? firebaseUser;
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.firebaseUser,
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? firebaseUser,
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => firebaseUser != null && user != null;
  bool get isHero => user?.role == UserRole.hero;
  bool get isCustomer => user?.role == UserRole.customer;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  AuthNotifier({
    required AuthService authService,
    required FirestoreService firestoreService,
    required NotificationService notificationService,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _notificationService = notificationService,
        super(const AuthState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    // If Firebase auth stream doesn't emit within 2s (e.g. simulator/network), show login so app isn't stuck on white splash
    Future.delayed(const Duration(seconds: 2), () {
      if (!state.isInitialized) {
        print('[AUTH] init timeout: showing login');
        state = const AuthState(isInitialized: true);
      }
    });

    _authSub = _authService.authStateChanges.listen(
      (user) {
        print('[AUTH] authStateChanges fired: user=${user?.uid ?? "null"}');
        if (user == null) {
          state = const AuthState(isInitialized: true);
          _userSub?.cancel();
        } else {
          state = state.copyWith(firebaseUser: user, isInitialized: true);
          _watchUserDocument(user.uid);
        }
      },
      onError: (e) {
        print('[AUTH] authStateChanges error: $e');
        state = const AuthState(isInitialized: true);
      },
    );
  }

  void _watchUserDocument(String uid) {
    _userSub?.cancel();
    _userSub = _firestoreService.watchUser(uid).listen(
      (user) {
        print('[AUTH] watchUser emitted: ${user?.email ?? "null"}');
        state = state.copyWith(
          user: user,
          isLoading: false,
          isInitialized: true,
        );
        if (user != null) {
          try {
            _notificationService.getAndSaveToken(
              userId: user.id,
              heroId: user.heroProfileId,
            );
          } catch (e) {
            print('[AUTH] notification token error: $e');
          }
        }
      },
      onError: (e) {
        print('[AUTH] watchUser error: $e');
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          error: 'Failed to load user profile: $e',
        );
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('[AUTH] signInWithEmail called: $email');
      state = state.copyWith(isLoading: true, error: null);
      await _authService.signInWithEmail(email: email, password: password);
      print('[AUTH] signInWithEmail succeeded');
    } on FirebaseAuthException catch (e) {
      print('[AUTH] signInWithEmail FirebaseAuthException: ${e.message}');
      state = state.copyWith(
          isLoading: false, error: e.message ?? 'Authentication failed');
    } catch (e) {
      print('[AUTH] signInWithEmail error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.message ?? 'Authentication failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authService: AuthService(),
    firestoreService: FirestoreService(),
    notificationService: NotificationService(),
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isHeroProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isHero;
});
