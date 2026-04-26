import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para monitorar o estado da autenticação
  Stream<User?> get userState => _auth.authStateChanges();

  // Login com Google atualizado para a versão 7.0+
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. A inicialização agora é obrigatória antes de qualquer chamada
      await GoogleSignIn.instance.initialize();

      // 2. O antigo signIn() foi substituído pelo authenticate()
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // 3. Autenticação e Autorização agora são processos separados
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Solicitamos os escopos explicitamente para obter o Access Token
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      // 4. Montamos a credencial do Firebase juntando as duas partes
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _updateUserData(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print("Erro no Google Sign-In: $e");
      return null;
    }
  }

  // Atualiza os dados do usuário no Firestore
  Future<void> _updateUserData(User user) async {
    DocumentReference userRef = _db.collection('users').doc(user.uid);

    return userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignIn': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Logout
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
