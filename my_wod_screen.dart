import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyWorkoutsScreen extends StatefulWidget {
  @override
  _MyWorkoutsScreenState createState() => _MyWorkoutsScreenState();
}
class AddWodDialog extends StatefulWidget {
  @override
  _AddWodDialogState createState() => _AddWodDialogState();
}

class _AddWodDialogState extends State<AddWodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _resultController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _workoutImage;
  bool _isBenchmark = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _workoutImage = File(image.path);
      });
    }
  }

  Future<void> _submitWorkout() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Aquí podrías subir la imagen a Firebase Storage
        String? imageUrl;
        if (_workoutImage != null) {
          // Implementar subida a Firebase Storage
          // imageUrl = await _uploadImage(_workoutImage!);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .add({
              'title': _titleController.text,
              'description': _descriptionController.text,
              'result': _resultController.text.isNotEmpty ? _resultController.text : null,
              'isBenchmark': _isBenchmark,
              'imageUrl': imageUrl,
              'date': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrenamiento guardado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el entrenamiento')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo Entrenamiento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del WOD',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Fran, Murph, Cindy...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del entrenamiento',
                  border: OutlineInputBorder(),
                  hintText: 'Describe el WOD, ejercicios, repeticiones...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor describe el entrenamiento';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _resultController,
                decoration: InputDecoration(
                  labelText: 'Resultado (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 15:30, 5 rondas, 100kg...',
                ),
              ),
              SizedBox(height: 16),
              
              // Imagen del entrenamiento
              if (_workoutImage != null)
                Column(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_workoutImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickImage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo),
                          SizedBox(width: 8),
                          Text('Añadir Imagen'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Checkbox para benchmark
              Row(
                children: [
                  Checkbox(
                    value: _isBenchmark,
                    onChanged: (value) {
                      setState(() => _isBenchmark = value ?? false);
                    },
                  ),
                  Text('Marcar como Benchmark'),
                  Icon(Icons.help_outline, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF03bb85),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class AddPRDialog extends StatefulWidget {
  @override
  _AddPRDialogState createState() => _AddPRDialogState();
}

class _AddPRDialogState extends State<AddPRDialog> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPR() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('personalRecords')
            .add({
              'exercise': _exerciseController.text,
              'weight': double.parse(_weightController.text),
              'reps': _repsController.text.isNotEmpty ? int.parse(_repsController.text) : null,
              'notes': _notesController.text,
              'date': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PR guardado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el PR')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo Personal Record',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: _exerciseController,
                decoration: InputDecoration(
                  labelText: 'Ejercicio',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Back Squat, Deadlift, Clean & Jerk...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el ejercicio';
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
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el peso';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Peso inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: InputDecoration(
                        labelText: 'Reps (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Condiciones, cómo te sentiste...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF03bb85),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Guardar PR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  int _selectedTab = 0; // 0: Mis WODs, 1: Mis PRs
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Entrenamientos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selector de pestañas
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Mis WODs', 0),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('Mis PRs', 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0 ? _buildMyWods() : _buildMyPRs(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedTab == 0) {
            _showAddWodDialog();
          } else {
            _showAddPRDialog();
          }
        },
        backgroundColor: Color(0xFF03bb85),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedTab = index);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedTab == index ? Color(0xFF03bb85) : Colors.grey[300],
        foregroundColor: _selectedTab == index ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text),
    );
  }

  Widget _buildMyWods() {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('workouts')
          .orderBy('date', descending: true)
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
                  'Aún no has registrado entrenamientos',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  '¡Pulsa el + para añadir tu primer WOD!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final workouts = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index].data() as Map<String, dynamic>;
            return _buildWorkoutCard(workout, workouts[index].id);
          },
        );
      },
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout, String workoutId) {
    final DateTime date = (workout['date'] as Timestamp).toDate();
    final bool isBenchmark = workout['isBenchmark'] ?? false;

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
                if (isBenchmark)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Benchmark',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              workout['title'] ?? 'Entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              workout['description'] ?? '',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            if (workout['result'] != null)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resultado: ${workout['result']}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 8),
            if (workout['imageUrl'] != null)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(workout['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteWorkout(workoutId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPRs() {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('personalRecords')
          .orderBy('date', descending: true)
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
                Icon(Icons.emoji_events, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Aún no has registrado PRs',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  '¡Pulsa el + para añadir tu primer PR!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final prs = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: prs.length,
          itemBuilder: (context, index) {
            final pr = prs[index].data() as Map<String, dynamic>;
            return _buildPRCard(pr, prs[index].id);
          },
        );
      },
    );
  }

  Widget _buildPRCard(Map<String, dynamic> pr, String prId) {
    final DateTime date = (pr['date'] as Timestamp).toDate();

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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'PR',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              pr['exercise'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Peso: ${pr['weight']} kg',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (pr['reps'] != null)
              Text(
                'Repeticiones: ${pr['reps']}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (pr['notes'] != null && pr['notes'].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Notas: ${pr['notes']}',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePR(prId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showAddWodDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWodDialog(),
    );
  }

  void _showAddPRDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPRDialog(),
    );
  }

  void _deleteWorkout(String workoutId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Entrenamiento'),
        content: Text('¿Estás seguro de que quieres eliminar este entrenamiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('workouts')
                  .doc(workoutId)
                  .delete();
              Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePR(String prId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar PR'),
        content: Text('¿Estás seguro de que quieres eliminar este PR?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('personalRecords')
                  .doc(prId)
                  .delete();
              Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}