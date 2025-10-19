import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_home_screen.dart';
import 'booking_screen.dart';

class UserHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // ✅ CORRECTO: isAdmin es un getter, NO lleva paréntesis
    if (authService.isAdmin) {
      return AdminHomeScreen();
    }

    // Si no es admin, mostrar pantalla normal de usuario
    return Scaffold(
      appBar: AppBar(
        title: Text('FlipFlow - Usuario'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido ${authService.userData['name'] ?? 'Usuario'}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Email: ${authService.currentUser?.email ?? 'No disponible'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF03bb85),
                foregroundColor: Colors.white,
              ),
              child: Text('Ver Clases Disponibles'),
            ),
          ],
        ),
      ),
    );
  }
}