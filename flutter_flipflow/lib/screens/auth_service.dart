import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar usuario
  Future<User?> registerWithEmail(
    String email, 
    String password, 
    String name
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Crear documento del usuario en Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user', // Por defecto es usuario normal
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return result.user;
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }

  // Login usuario
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Verificar si es admin
  Future<bool> isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
        
    return userDoc.exists && userDoc['role'] == 'admin';
  }

  // Stream de cambios de autenticación
  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}
