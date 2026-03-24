import 'package:flutter/material.dart';

import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';

class PassengerProfileFormScreen extends StatefulWidget {
  const PassengerProfileFormScreen({super.key, this.profile});

  final PassengerProfile? profile;

  @override
  State<PassengerProfileFormScreen> createState() => _PassengerProfileFormScreenState();
}

class _PassengerProfileFormScreenState extends State<PassengerProfileFormScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController idController;
  late TextEditingController noteController;
  bool isSaving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile?.fullName ?? '');
    phoneController = TextEditingController(text: widget.profile?.phone ?? '');
    idController = TextEditingController(text: widget.profile?.identityNumber ?? '');
    noteController = TextEditingController(text: widget.profile?.note ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    idController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      isSaving = true;
      error = null;
    });
    final userId = AuthRepository.instance.currentUser?.id ?? 1;
    try {
      if (widget.profile == null) {
        await ProfileRepository.instance.createPassengerProfile(
          userId: userId,
          fullName: nameController.text.trim(),
          phone: phoneController.text.trim(),
          identityNumber: idController.text.trim(),
          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        );
      } else {
        await ProfileRepository.instance.updatePassengerProfile(
          PassengerProfile(
            id: widget.profile!.id,
            fullName: nameController.text.trim(),
            phone: phoneController.text.trim(),
            identityNumber: idController.text.trim(),
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.profile != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(title: Text(isEdit ? 'Edit passenger' : 'Add passenger')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ),
              12.vSpace,
            ],
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
            12.vSpace,
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            12.vSpace,
            TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID number')),
            12.vSpace,
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
            20.vSpace,
            ElevatedButton(
              onPressed: isSaving ? null : _save,
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
