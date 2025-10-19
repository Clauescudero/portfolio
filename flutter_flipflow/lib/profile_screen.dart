import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  bool _isEditing = false;
  bool _isChangingPassword = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeightHistory();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _weightController.text = _userData['currentWeight']?.toString() ?? '';
          _heightController.text = _userData['height']?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _loadWeightHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot weightSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weightHistory')
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      
      setState(() {
        _weightHistory = weightSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'weight': data['weight'],
            'date': (data['date'] as Timestamp).toDate(),
            'id': doc.id,
          };
        }).toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Aquí podrías subir la imagen a Firebase Storage
      _uploadProfileImage(File(image.path));
    }
  }

  Future<void> _uploadProfileImage(File image) async {
    // Implementar subida a Firebase Storage
    // Por ahora solo guardamos localmente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imagen de perfil actualizada')),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final updates = {
          'fullName': _userData['fullName'],
          'age': _userData['age'],
          'height': double.tryParse(_heightController.text),
          'currentWeight': double.tryParse(_weightController.text),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update(updates);

        // Guardar en historial de peso si cambió
        if (_weightController.text.isNotEmpty) {
          final newWeight = double.tryParse(_weightController.text);
          final currentWeight = _userData['currentWeight'];
          
          if (newWeight != null && newWeight != currentWeight) {
            await _addWeightToHistory(newWeight);
          }
        }

        // Actualizar displayName en Auth
        await user.updateDisplayName(_userData['fullName']);

        setState(() => _isEditing = false);
        await _loadUserData(); // Recargar datos
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }
  }

  Future<void> _addWeightToHistory(double weight) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weightHistory')
          .add({
            'weight': weight,
            'date': FieldValue.serverTimestamp(),
          });
      await _loadWeightHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header con avatar y datos básicos
            _buildProfileHeader(user),
            SizedBox(height: 20),
            
            // Tarifa actual
            _buildMembershipCard(),
            SizedBox(height: 20),
            
            if (_isChangingPassword)
              _buildChangePasswordForm()
            else
              _buildProfileForm(authService),
            
            // Historial de peso
            if (!_isEditing && !_isChangingPassword)
              _buildWeightHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF03bb85),
              backgroundImage: _profileImage != null 
                  ? FileImage(_profileImage!) 
                  : (_userData['profileImageUrl'] != null
                      ? NetworkImage(_userData['profileImageUrl']) as ImageProvider
                      : null),
              child: _profileImage == null && _userData['profileImageUrl'] == null
                  ? Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _pickImage,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          _userData['fullName'] ?? 'Usuario',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          user?.email ?? '',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _userData['role'] == 'admin' ? 'Administrador' : 'Usuario',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard() {
    final membershipType = _userData['membership'] ?? 'Básica';
    final classesRemaining = _userData['classesRemaining'] ?? 0;
    final renewalDate = _userData['renewalDate'] != null 
        ? (_userData['renewalDate'] as Timestamp).toDate()
        : DateTime.now().add(Duration(days: 30));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Color(0xFF03bb85)),
                SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Información personal
          Text(
            'Información Personal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            initialValue: _userData['fullName'] ?? '',
            enabled: _isEditing,
            onChanged: (value) => _userData['fullName'] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            initialValue: authService.currentUser?.email ?? '',
            enabled: false,
          ),
          SizedBox(height: 16),
          
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Edad',
              prefixIcon: Icon(Icons.cake),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            initialValue: _userData['age']?.toString() ?? '',
            enabled: _isEditing,
            onChanged: (value) => _userData['age'] = int.tryParse(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu edad';
              }
              final age = int.tryParse(value);
              if (age == null || age < 10 || age > 100) {
                return 'Edad inválida';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  enabled: _isEditing,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Altura (cm)',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: _isEditing,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF03bb85),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Guardar Cambios'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _loadUserData(); // Recargar datos originales
                      });
                    },
                    child: Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => setState(() => _isChangingPassword = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Cambiar Contraseña'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightHistory() {
    if (_weightHistory.isEmpty) return SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Peso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ..._weightHistory.map((entry) => ListTile(
              leading: Icon(Icons.monitor_weight, color: Color(0xFF03bb85)),
              title: Text('${entry['weight']} kg'),
              trailing: Icon(Icons.trending_up, color: Colors.green),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambiar Contraseña',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        
        TextFormField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Contraseña actual',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        
        TextFormField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'Nueva contraseña',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirmar nueva contraseña',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF03bb85),
                  foregroundColor: Colors.white,
                ),
                child: Text('Cambiar Contraseña'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isChangingPassword = false),
                child: Text('Cancelar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMembershipOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Tarifa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMembershipOption('Básica', '8 clases/mes', '49€'),
              _buildMembershipOption('Premium', 'Clases ilimitadas', '79€'),
              _buildMembershipOption('Competidor', '12 clases/mes + seguimiento', '99€'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipOption(String name, String description, String price) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.star, color: Colors.orange),
        title: Text(name),
        subtitle: Text(description),
        trailing: Text(price, style: TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          _updateMembership(name);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _updateMembership(String membership) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'membership': membership,
            'renewalDate': DateTime.now().add(Duration(days: 30)),
          });
      
      setState(() {
        _userData['membership'] = membership;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarifa actualizada a $membership')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _isChangingPassword = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contraseña cambiada correctamente')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al cambiar contraseña';
      if (e.code == 'wrong-password') {
        errorMessage = 'La contraseña actual es incorrecta';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La nueva contraseña es muy débil';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
