import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para monitorar o estado da autenticação
  Stream<User?> get userState => _auth.authStateChanges();

  // Login com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Inicia o fluxo de autenticação do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtém os detalhes da autenticação
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Cria uma nova credencial
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz o login no Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Salva ou atualiza os dados do usuário no Firestore
      if (userCredential.user != null) {
        await _updateUserData(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print("Erro no Google Sign-In: $e");
      return null;
    }
  }

  // Atualiza os dados do usuário no Firestore (Cloud Firestore)
  Future<void> _updateUserData(User user) async {
    DocumentReference userRef = _db.collection('users').doc(user.uid);

    return userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignIn': DateTime.now(),
      // 'role' será definido na tela de seleção de modo se for o primeiro acesso
    }, SetOptions(merge: true));
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
