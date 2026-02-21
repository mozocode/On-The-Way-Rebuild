import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/firebase_config.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseConfig.auth;
  final _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _updateLastLogin(credential.user!.uid);
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null) {
      await credential.user!.updateDisplayName(displayName);
    }
    await _createUserDocument(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      phone: phone,
    );
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _createUserDocument({
    required String uid,
    required String email,
    String? displayName,
    String? phone,
    String? photoUrl,
  }) async {
    await FirebaseConfig.firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': 'customer',
      'settings': {
        'pushEnabled': true,
        'language': 'en',
        'emailNotifications': true,
        'smsNotifications': true,
      },
      'emailVerified': false,
      'phoneVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _createOrUpdateUserFromSocial(
      userCredential.user!,
      displayName: googleUser.displayName,
    );
    return userCredential;
  }

  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    final displayName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    await _createOrUpdateUserFromSocial(
      userCredential.user!,
      displayName: displayName.isNotEmpty ? displayName : null,
    );
    return userCredential;
  }

  Future<void> _createOrUpdateUserFromSocial(User user,
      {String? displayName}) async {
    final doc = await FirebaseConfig.firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      await _createUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName ?? user.displayName,
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
      );
    } else {
      await _updateLastLogin(user.uid);
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    await FirebaseConfig.firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }
}
