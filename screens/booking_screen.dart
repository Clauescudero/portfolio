import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_booking_screen.dart'; 

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.isAdmin; // ✅ Getter simple, NO paréntesis
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin - Reservas' : 'Reservas FlipFlow'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBookingScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Clases Disponibles', 0),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('Mis Reservas', 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0 
                ? _buildAvailableClasses()
                : _buildMyBookings(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedIndex = index);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedIndex == index ? Color(0xFF03bb85) : Colors.grey[300],
        foregroundColor: _selectedIndex == index ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text),
    );
  }

  Widget _buildAvailableClasses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('date', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No hay clases disponibles',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final classes = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index].data() as Map<String, dynamic>;
            return _buildClassCard(classData, classes[index].id);
          },
        );
      },
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, String classId) {
    final DateTime date = (classData['date'] as Timestamp).toDate();
    final bool isFull = (classData['bookedUsers']?.length ?? 0) >= (classData['capacity'] ?? 20);
    final bool userBooked = (classData['bookedUsers']?.contains(user?.uid) ?? false);

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  classData['activity'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getActivityColor(classData['activity']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    classData['time'],
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Entrenador: ${classData['trainer']}'),
            Text('Día: ${DateFormat('EEEE, d MMMM', 'es_ES').format(date)}'),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plazas: ${(classData['bookedUsers']?.length ?? 0)}/${classData['capacity'] ?? 20}',
                  style: TextStyle(
                    color: isFull ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userBooked)
                  Text(
                    'RESERVADO',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (!isFull)
                  ElevatedButton(
                    onPressed: () => _bookClass(classId, classData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF03bb85),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Reservar'),
                  )
                else
                  Text(
                    'COMPLETO',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid)
          .where('date', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No tienes reservas futuras',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            return _buildBookingCard(booking, bookings[index].id);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String bookingId) {
    final DateTime date = (booking['date'] as Timestamp).toDate();

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getActivityColor(booking['activity']),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.fitness_center, color: Colors.white),
        ),
        title: Text(
          booking['activity'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${DateFormat('EEEE, d MMMM', 'es_ES').format(date)} · ${booking['time']}'),
            Text('Con ${booking['trainer']}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _cancelBooking(bookingId, booking['classId']),
        ),
      ),
    );
  }

  Future<void> _bookClass(String classId, Map<String, dynamic> classData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'classId': classId,
        'activity': classData['activity'],
        'trainer': classData['trainer'],
        'date': classData['date'],
        'time': classData['time'],
        'bookedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('classes').doc(classId).update({
        'bookedUsers': FieldValue.arrayUnion([user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Clase reservada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reservar la clase'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId, String classId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Reserva'),
        content: Text('¿Estás seguro de que quieres cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .delete();

                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .update({
                  'bookedUsers': FieldValue.arrayRemove([user?.uid]),
                });

                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reserva cancelada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cancelar la reserva'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String activity) {
    switch (activity.toLowerCase()) {
      case 'hyrox': return Colors.red;
      case 'crossfit': return Color(0xFF0EBEB0);
      case 'gymnásticos': return Color(0xFFE09B9B);
      case 'core y estiradores': return Colors.pink;
      case 'competidores': return Colors.blue;
      case 'iniciación crossfit': return Colors.blue;
      case 'yoga': return Color(0xFF63C266);
      case 'halterofilia': return Color(0xFFD1A0DA);
      default: return Colors.orange;
    }
  }
}
