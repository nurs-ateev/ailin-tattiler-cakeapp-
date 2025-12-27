import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ailin_tattileri_app/core/services/location_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address Controllers
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userRole = 'client';
  // Initially FALSE (Hidden). Becomes TRUE if user is Inside Zone (or already has address).
  bool _showAddressFields = false;

  double? _geoLat;
  double? _geoLng;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      _nameController.text =
          data['fullName'] ?? data['name'] ?? user.displayName ?? '';
      _phoneController.text = data['phone'] ?? user.phoneNumber ?? '';

      _regionController.text = data['address_region'] ?? '';
      _cityController.text = data['address_city'] ?? '';

      if (data['address_street'] != null) {
        _streetController.text = data['address_street'];
      } else {
        _streetController.text = data['address'] ?? '';
      }

      _apartmentController.text = data['address_apartment'] ?? '';
      _userRole = data['role'] ?? 'client';

      if (data['geo_lat'] != null) {
        _geoLat = data['geo_lat'];
        _geoLng = data['geo_lng'];
      }

      // If we have an address saved, OR if user is a partner, show the fields
      if (_streetController.text.isNotEmpty || _userRole == 'partner') {
        _showAddressFields = true;
      }
    }
    setState(() => _isLoading = false);
  }

  void _showOutsideZoneDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text("Ой! Сіз алыстасыз", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          "$message\n\nӨкінішке орай, біз тек Жетісай қаласы мен маңына (+20км) жеткіземіз.",
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Түсінікті, мәзірді көру"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Жабу", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFromGPS() async {
    setState(() {
      _isSaving = true;
      // We don't hide fields here immediately, in case they were already open.
      // But if verification fails, we might hide them?
      // User requested: "if outside ... nothing comes out".
      // If they were already open, maybe we should close them if check fails?
      // Let's assume if check fails, we hide them to enforce rule.
    });

    try {
      // 1. Verify Radius (Throws exception if outside)
      final position = await _locationService.verifyLocation();
      _geoLat = position.latitude;
      _geoLng = position.longitude;

      debugPrint("📍 Coordinates verified: ${_geoLat}, ${_geoLng}");

      // 2. Geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _regionController.text = place.administrativeArea ?? '';
          _cityController.text =
              place.locality ?? place.subAdministrativeArea ?? '';

          String fullStreet = "";
          // Aggressive street finding
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            fullStreet = place.thoroughfare!;
            if (place.subThoroughfare != null &&
                place.subThoroughfare!.isNotEmpty) {
              fullStreet += ", ${place.subThoroughfare}";
            }
          } else if (place.street != null &&
              place.street!.isNotEmpty &&
              place.street != place.locality) {
            fullStreet = place.street!;
          } else if (place.name != null &&
              place.name!.isNotEmpty &&
              place.name != place.locality) {
            fullStreet = place.name!;
          }

          if (fullStreet.isNotEmpty) {
            _streetController.text = fullStreet;
          }

          // SUCCESS: Show fields
          _showAddressFields = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Аймақ расталды! Мекенжайды толтырыңыз."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // GPS verified ok, but no text address.
        // Still show fields to allow manual entry.
        setState(() => _showAddressFields = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Аймақ расталды. Мекенжайды қолмен енгізіңіз."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();

        setState(() {
          // If check fails (outside zone), ensure fields are hidden
          _showAddressFields = false;
        });

        // Check for specific "outside zone" error
        if (errorMsg.contains("за пределами")) {
          _showOutsideZoneDialog(errorMsg.replaceAll('Exception: ', ''));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Ошибка GPS: $errorMsg"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    // Safety: if fields are hidden, we shouldn't save address?
    // Or if name changed, save name?
    // Let's assume user wants to save everything visible.

    // If address fields are visible, require coords (except for partners who can enter manually)
    if (_showAddressFields &&
        _userRole != 'partner' &&
        (_geoLat == null || _geoLng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GPS растау қажет"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> dataToSave = {
          'fullName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Only save address if fields are visible (verified)
        if (_showAddressFields) {
          String fullAddress =
              "${_regionController.text}, ${_cityController.text}, ${_streetController.text}";
          if (_apartmentController.text.isNotEmpty) {
            fullAddress += ", кв/эт: ${_apartmentController.text}";
          }

          dataToSave.addAll({
            'address_region': _regionController.text.trim(),
            'address_city': _cityController.text.trim(),
            'address_street': _streetController.text.trim(),
            'address_apartment': _apartmentController.text.trim(),
            'address': fullAddress,
            'geo_lat': _geoLat,
            'geo_lng': _geoLng,
          });
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(dataToSave, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Деректер сақталды"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка сохранения: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Жеке деректер", style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Негізгі ақпарат"),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      label: "Толық аты-жөні",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: "Телефон нөмірі",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle("Жеткізу мекенжайы"),
                    const SizedBox(height: 4),

                    if (!_showAddressFields)
                      const Text(
                        "Жеткізу аймағын тексеру үшін GPS түймесін басыңыз (Жетісай +20км).",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // GPS Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _updateFromGPS,
                        icon: const Icon(Icons.location_searching),
                        label: const Text("Мекенжайды тексеру (GPS)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    // ADDRESS FIELDS (Hidden until GPS success)
                    if (_showAddressFields) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Аймақ расталды. Мекенжайды толтырыңыз.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _regionController,
                        label: "Облыс",
                        hint: "Түркістан обл.",
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _cityController,
                        label: "Қала / Аудан",
                        hint: "Жетісай қ.",
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _streetController,
                        label: "Көше, Үй",
                        hint: "Абай к-сі, 10",
                        maxLines: 2,
                        validator: (v) =>
                            v!.isEmpty ? "Мекенжайды енгізіңіз" : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _apartmentController,
                        label: "Пәтер / Қабат",
                        hint: "42 пәтер",
                        icon: Icons.meeting_room,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Өзгерістерді сақтау",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
