import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Luồng lắng nghe trạng thái user (để auto login)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký
  Future<User?> signUp(String email, String password) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Đăng nhập
  Future<User?> signIn(String email, String password) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}