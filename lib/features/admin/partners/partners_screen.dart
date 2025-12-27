import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/partner_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Магазины / Заведения",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddPartnerDialog,
            icon: const Icon(
              Icons.add_business_rounded,
              color: AppColors.primary,
            ),
            tooltip: "Добавить заведение",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('partners').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final partners =
              snapshot.data?.docs
                  .map(
                    (doc) => PartnerModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList() ??
              [];

          if (partners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  const Text("Нет добавленных заведений"),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddPartnerDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Добавить"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final partner = partners[index];
              return _PartnerCard(
                partner: partner,
                onDelete: () => _deletePartner(partner),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deletePartner(PartnerModel partner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить заведение?"),
        content: Text(
          "Вы уверены, что хотите удалить '${partner.name}'? Это действие нельзя отменить.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Удалить"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('partners').doc(partner.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Заведение успешно удалено")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
      }
    }
  }

  void _showAddPartnerDialog() {
    final nameController = TextEditingController();
    final personController = TextEditingController();
    final phoneController = TextEditingController();
    // Unique suffix to prevent duplicate logins
    final randomSuffix = Random().nextInt(9000) + 1000;

    String transliterate(String text) {
      const cyrillic = 'абвгдейжзийклмнопрстуфхцчшщыэюя';
      const latin = [
        'a',
        'b',
        'v',
        'g',
        'd',
        'e',
        'y',
        'zh',
        'z',
        'i',
        'y',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'r',
        's',
        't',
        'u',
        'f',
        'h',
        'ts',
        'ch',
        'sh',
        'shch',
        'y',
        'e',
        'yu',
        'ya',
      ];
      String result = text.toLowerCase();
      for (int i = 0; i < cyrillic.length; i++) {
        result = result.replaceAll(cyrillic[i], latin[i]);
      }
      return result.replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    String generatedEmail = '';
    String generatedPassword = '123partner';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Добавить заведение"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    enabled: !isSaving,
                    controller: nameController,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val.trim().isNotEmpty) {
                          final transName = transliterate(val.trim());
                          generatedEmail = '$transName$randomSuffix@partner.kz';
                          generatedPassword = '$transName$randomSuffix';
                        } else {
                          generatedEmail = '';
                          generatedPassword = '123partner';
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Название заведения",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: personController,
                    decoration: const InputDecoration(
                      labelText: "Контактное лицо",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Телефон",
                      hintText: "+7 (777) 000-00-00",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                  ),
                  const SizedBox(height: 12),
                  if (generatedEmail.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Данные для входа в приложение:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCredentialRow("Email:", generatedEmail),
                          const SizedBox(height: 4),
                          _buildCredentialRow("Пароль:", generatedPassword),
                          const SizedBox(height: 8),
                          const Text(
                            "Передайте эти данные владельцу заведения",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text("Отмена"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;
                        setDialogState(() => isSaving = true);

                        try {
                          final authService = AuthService();
                          final partnerUid = await authService
                              .createPartnerAccountByAdmin(
                                email: generatedEmail,
                                password: generatedPassword,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                              );

                          final partnerData = {
                            'userId': partnerUid,
                            'name': nameController.text.trim(),
                            'contactPerson': personController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'invitedEmail': generatedEmail,
                            'invitedPassword': generatedPassword,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          await _firestore
                              .collection('partners')
                              .add(partnerData);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Аккаунт заведения успешно создан",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Ошибка: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Добавить"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Скопировано"),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback onDelete;

  const _PartnerCard({required this.partner, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Контакт: ${partner.contactPerson}",
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_outlined, "Телефон", partner.phone),
          if (partner.invitedEmail != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(Icons.email_outlined, "Логин", partner.invitedEmail!),
          ],
          if (partner.invitedPassword != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.lock_outline,
              "Пароль",
              partner.invitedPassword!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.copy, size: 14, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
