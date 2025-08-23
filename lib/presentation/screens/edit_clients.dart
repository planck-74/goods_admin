import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_state.dart';
import 'package:goods_admin/data/functions/open_google_maps.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/client_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class EditClients extends StatefulWidget {
  const EditClients({super.key});

  @override
  State<EditClients> createState() => _EditClientsState();
}

class _EditClientsState extends State<EditClients> {
  final TextEditingController _searchController = TextEditingController();
  List<ClientModel>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    context.read<GetClientDataCubit>().getClientData();
    super.initState();
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });

    try {
      List<QueryDocumentSnapshot> docs =
          await context.read<GetClientDataCubit>().searchClientsByName(query);

      List<ClientModel> clients = docs
          .map((doc) => ClientModel.fromMap(doc.data() as Map<String, dynamic>))
          .where(_shouldDisplayClient)
          .toList();

      setState(() {
        _searchResults = clients;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint("Error searching clients: $e");
    }
  }

  bool _shouldDisplayClient(ClientModel client) {
    // Don't display clients without name or phone number
    if (client.businessName.isEmpty ||
        client.phoneNumber.isEmpty ||
        client.phoneNumber == null) {
      return false;
    }
    return true;
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    return clients.where(_shouldDisplayClient).toList();
  }

  Future<void> refreshSearchResults() async {
    if (_searchController.text.isNotEmpty) {
      await _searchClients(_searchController.text);
    } else {
      context.read<GetClientDataCubit>().getClientData();
    }
  }

  void _showClientDetails(ClientModel client) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailsDialog(
        client: client,
        onClientUpdated: refreshSearchResults,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text('العملاء', style: TextStyle(color: whiteColor)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSearchField(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? RefreshIndicator(
                        onRefresh: refreshSearchResults,
                        child: _buildClientList(_searchResults!),
                      )
                    : BlocBuilder<GetClientDataCubit, GetClientDataState>(
                        builder: (context, state) {
                          if (state is GetClientDataLoading) {
                            return const Center(
                                child: CircularProgressIndicator(
                              color: primaryColor,
                            ));
                          } else if (state is GetClientDataSuccess) {
                            List<ClientModel> filteredClients =
                                _filterClients(state.clients);
                            return RefreshIndicator(
                              onRefresh: refreshSearchResults,
                              child: filteredClients.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'لا يوجد عملاء',
                                        style: TextStyle(
                                            color: darkBlueColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : _buildClientList(filteredClients),
                            );
                          } else if (state is GetClientDataError) {
                            return Center(
                                child: Text('Error: ${state.message}'));
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return BlocBuilder<GetClientDataCubit, GetClientDataState>(
      builder: (context, state) {
        if (state is GetClientDataSuccess) {
          List<ClientModel> validClients = _filterClients(state.clients);

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي العملاء',
                      validClients.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        cursorHeight: 25,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث عن عميل',
          hintStyle: TextStyle(color: darkBlueColor, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          _searchClients(value);
        },
      ),
    );
  }

  Widget _buildClientList(List<ClientModel> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        ClientModel client = clients[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
          child: GestureDetector(
            onTap: () => _showClientDetails(client),
            child: _buildClientCard(client),
          ),
        );
      },
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: client.imageUrl.isNotEmpty
                  ? Image.network(
                      client.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 40),
                    )
                  : const Icon(Icons.person, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildClientDetails(client),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildClientDetails(ClientModel client) {
    // Build address string from government, town, and area
    List<String> addressParts = [];
    if (client.government.isNotEmpty) addressParts.add(client.government);
    if (client.town.isNotEmpty) addressParts.add(client.town);
    if (client.area.isNotEmpty) addressParts.add(client.area);
    String fullAddress = addressParts.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          client.businessName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (client.category.isNotEmpty)
          Text(
            client.category,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        const SizedBox(height: 4),
        if (fullAddress.isNotEmpty)
          Text(
            fullAddress,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Text(
          client.phoneNumber,
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        ),
      ],
    );
  }
}

class ClientDetailsDialog extends StatefulWidget {
  final ClientModel client;
  final VoidCallback onClientUpdated;

  const ClientDetailsDialog({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  @override
  State<ClientDetailsDialog> createState() => _ClientDetailsDialogState();
}

class _ClientDetailsDialogState extends State<ClientDetailsDialog> {
  late TextEditingController _businessNameController;
  late TextEditingController _categoryController;
  late TextEditingController _phoneController;
  late TextEditingController _secondPhoneController;
  late TextEditingController _governmentController;
  late TextEditingController _townController;
  late TextEditingController _areaController;
  late TextEditingController _addressTypedController;

  bool _isEditing = false;
  bool _isUpdating = false;
  bool _isUploadingImage = false;
  String? _newImageUrl;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.client.businessName);
    _categoryController = TextEditingController(text: widget.client.category);
    _phoneController = TextEditingController(text: widget.client.phoneNumber);
    _secondPhoneController =
        TextEditingController(text: widget.client.secondPhoneNumber);
    _governmentController =
        TextEditingController(text: widget.client.government);
    _townController = TextEditingController(text: widget.client.town);
    _areaController = TextEditingController(text: widget.client.area);
    _addressTypedController =
        TextEditingController(text: widget.client.addressTyped ?? '');
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingImage = true;
        });

        await _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      // Delete the previous image if it exists
      if (widget.client.imageUrl.isNotEmpty) {
        try {
          final Reference oldImageRef =
              FirebaseStorage.instance.refFromURL(widget.client.imageUrl);
          await oldImageRef.delete();
        } catch (e) {
          // If deletion fails, continue with upload (maybe the image doesn't exist)
          debugPrint('Could not delete old image: $e');
        }
      }

      // Create a reference to the location where the new image will be stored
      final String fileName =
          'client_images/${widget.client.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      // Upload the new image
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _newImageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الصورة بنجاح')),
      );
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصورة: $e')),
      );
    }
  }

  Future<void> _updateClient() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      Map<String, dynamic> updateData = {
        'businessName': _businessNameController.text,
        'category': _categoryController.text,
        'phoneNumber': _phoneController.text,
        'secondPhoneNumber': _secondPhoneController.text,
        'government': _governmentController.text,
        'town': _townController.text,
        'area': _areaController.text,
        'addressTyped': _addressTypedController.text,
      };

      // Add image URL if a new image was uploaded
      if (_newImageUrl != null) {
        updateData['imageUrl'] = _newImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(widget.client.uid)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بيانات العميل بنجاح')),
      );

      widget.onClientUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحديث: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'تفاصيل العميل',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(
                      _isEditing ? Icons.cancel : Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image with edit capability
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: _isUploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : widget.client.imageUrl.isNotEmpty
                                          ? Image.network(
                                              widget.client.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.person,
                                                      size: 50),
                                            )
                                          : const Icon(Icons.person, size: 50),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Client Details
                    _buildDetailField(
                        'اسم النشاط', _businessNameController, _isEditing),
                    _buildDetailField('الفئة', _categoryController, _isEditing),
                    _buildDetailField(
                        'رقم الهاتف الأول', _phoneController, _isEditing),
                    _buildDetailField('رقم الهاتف الثاني',
                        _secondPhoneController, _isEditing),

                    // Address Fields
                    const Text(
                      'العنوان',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailField(
                        'المحافظة', _governmentController, _isEditing),
                    _buildDetailField('المدينة', _townController, _isEditing),
                    _buildDetailField('المنطقة', _areaController, _isEditing),
                    _buildDetailField(
                        'العنوان المكتوب', _addressTypedController, _isEditing),

                    const SizedBox(height: 16),

                    // Status and Statistics
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلومات إضافية',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('معرف العميل', widget.client.uid),
                          _buildInfoRow('إجمالي المدخرات',
                              '${widget.client.totalSavings.toStringAsFixed(2)} جنيه'),
                          _buildInfoRow('إجمالي المدفوعات',
                              '${widget.client.totalPayments.toStringAsFixed(2)} جنيه'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              openMap(widget.client.geoLocation.latitude,
                                  widget.client.geoLocation.longitude);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.blue, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'عرض الموقع على الخريطة',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            if (_isEditing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateClient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isUpdating
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('حفظ التغييرات',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(
      String label, TextEditingController controller, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          isEditing
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.text.isEmpty ? 'غير محدد' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          controller.text.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _secondPhoneController.dispose();
    _governmentController.dispose();
    _townController.dispose();
    _areaController.dispose();
    _addressTypedController.dispose();
    super.dispose();
  }
}
