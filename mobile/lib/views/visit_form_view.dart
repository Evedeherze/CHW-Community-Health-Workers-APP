// mobile/lib/views/visit_form_view.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/visit_record.dart';
import '../services/sync_service.dart';
import '../utils/validators.dart';

class VisitFormView extends StatefulWidget {
  final SyncService syncService;

  const VisitFormView({super.key, required this.syncService});

  @override
  State<VisitFormView> createState() => _VisitFormViewState();
}

class _VisitFormViewState extends State<VisitFormView> {
  final _formKey = GlobalKey<FormState>();

  final _chwIdController = TextEditingController(text: 'CHW-KKG-04');
  final _villageController = TextEditingController(text: 'Shibuye');
  final _patientNameController = TextEditingController();
  final _bpController = TextEditingController(text: '120/80');
  final _tempController = TextEditingController(text: '37.0');
  final _notesController = TextEditingController();

  String _visitType = 'Maternal';
  String _urgencyLevel = 'Routine';
  bool _isSaving = false;
  String _allocatedId = const Uuid().v4();

  @override
  void dispose() {
    _chwIdController.dispose();
    _villageController.dispose();
    _patientNameController.dispose();
    _bpController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final record = VisitRecord(
        localId: _allocatedId,
        chwId: _chwIdController.text.trim(),
        patientName: _patientNameController.text.trim(),
        villageName: _villageController.text.trim(),
        visitType: _visitType,
        vitalsBp: _bpController.text.trim(),
        vitalsTemp: double.parse(_tempController.text.trim()),
        urgencyLevel: _urgencyLevel,
        visitNotes: _notesController.text.trim(),
        createdAtLocal: DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Pending',
      );

      // Save locally (Zero data loss guarantee) and auto-sync if online
      await widget.syncService.saveRecordLocallyAndTrySync(record);

      // Allocate fresh new ID for next entry
      _allocatedId = const Uuid().v4();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.syncService.isOnline
                ? 'Record saved and synced to central database!'
                : 'Offline: Record saved to local sync queue.',
          ),
          backgroundColor: widget.syncService.isOnline ? Colors.green[800] : Colors.orange[800],
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset patient fields for next rapid entry
      _patientNameController.clear();
      _notesController.clear();
      FocusScope.of(context).requestFocus(FocusNode());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              color: const Color(0xFFECFDF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allocated Entry ID (Auto per entry)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                        Text(
                          _allocatedId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF059669), size: 20),
                      tooltip: 'Allocate New ID',
                      onPressed: () => setState(() => _allocatedId = const Uuid().v4()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1.5,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Community Health Worker Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _chwIdController,
                            decoration: const InputDecoration(
                              labelText: 'CHW ID *',
                              prefixIcon: Icon(Icons.badge, color: Colors.blueAccent),
                            ),
                            validator: (v) => FormValidators.validateRequired(v, 'CHW ID'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _villageController,
                            decoration: const InputDecoration(
                              labelText: 'Village / Cluster *',
                              prefixIcon: Icon(Icons.location_on, color: Colors.blueAccent),
                            ),
                            validator: (v) => FormValidators.validateRequired(v, 'Village name'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1.5,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient & Clinical Vitals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _patientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Full Name *',
                        hintText: 'e.g. Mary Atieno',
                        prefixIcon: Icon(Icons.person, color: Color(0xFF059669)),
                      ),
                      validator: FormValidators.validatePatientName,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _visitType,
                            decoration: const InputDecoration(labelText: 'Visit Type *'),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'Maternal', child: Text('Maternal')),
                              DropdownMenuItem(value: 'Child', child: Text('Child')),
                              DropdownMenuItem(value: 'General', child: Text('General')),
                            ],
                            onChanged: (val) => setState(() => _visitType = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _urgencyLevel,
                            decoration: const InputDecoration(labelText: 'Urgency Level *'),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                              DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                              DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                            ],
                            onChanged: (val) => setState(() => _urgencyLevel = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bpController,
                            decoration: const InputDecoration(
                              labelText: 'Blood Pressure *',
                              hintText: '120/80',
                              prefixIcon: Icon(Icons.favorite, color: Colors.redAccent),
                            ),
                            validator: FormValidators.validateBp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tempController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Temp (°C) *',
                              hintText: '37.0',
                              prefixIcon: Icon(Icons.thermostat, color: Colors.amberAccent),
                            ),
                            validator: FormValidators.validateTemp,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Field Notes (Optional)',
                        hintText: 'Clinical observations, medications, referral notes...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitForm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving Record...' : 'Save Visit Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
