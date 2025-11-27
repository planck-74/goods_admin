import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/presentation/screens/chat_screens/full_screen_image_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_state.dart';
import 'package:goods_admin/data/functions/open_google_maps.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/client_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:intl/intl.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClientModel>? _searchResults;
  bool _isSearching = false;
  Map<String, String> _clientNotes = {};

  @override
  void initState() {
    context.read<GetClientDataCubit>().getClientData();
    _loadAllClientNotes();
    super.initState();
  }

  Future<void> _loadAllClientNotes() async {
    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('client_notes')
          .get();

      if (notesSnapshot.exists) {
        final data = notesSnapshot.data();
        if (data != null) {
          setState(() {
            _clientNotes = Map<String, String>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
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
      List<QueryDocumentSnapshot> docs = await context
          .read<GetClientDataCubit>()
          .searchClientsComprehensive(query);

      List<ClientModel> clients = docs
          .map((doc) => ClientModel.fromDocumentSnapshot(doc))
          .where(_shouldDisplayClient)
          .toList();

      Map<String, ClientModel> uniqueClients = {};
      for (ClientModel client in clients) {
        uniqueClients[client.uid] = client;
      }

      setState(() {
        _searchResults = uniqueClients.values.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint("Error searching clients: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في البحث: $e')),
      );
    }
  }

  bool _shouldDisplayClient(ClientModel client) {
    if (client.businessName.isEmpty || client.phoneNumber.isEmpty) {
      return false;
    }
    return true;
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    return clients.where(_shouldDisplayClient).toList();
  }

  Future<void> refreshSearchResults() async {
    await _loadAllClientNotes();
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
        clientNote: _clientNotes[client.uid],
        onClientUpdated: refreshSearchResults,
        onNoteUpdated: (note) {
          setState(() {
            if (note.isEmpty) {
              _clientNotes.remove(client.uid);
            } else {
              _clientNotes[client.uid] = note;
            }
          });
        },
      ),
    );
  }

  void _navigateToChat(ClientModel client) {
    Navigator.pushNamed(
      context,
      '/ChatScreen',
      arguments: {
        'clientId': client.uid,
        'clientData': {
          'businessName': client.businessName,
          'imageUrl': client.imageUrl,
          'phoneNumber': client.phoneNumber,
          'category': client.category,
          'government': client.government,
          'town': client.town,
          'area': client.area,
        },
      },
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'غير متوفر';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    } else if (difference.inDays < 365) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    }
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
          int activeClients = validClients.where((c) {
            if (c.lastTokenUpdate == null) return false;
            final diff = DateTime.now().difference(c.lastTokenUpdate!);
            return diff.inDays < 7;
          }).length;

          int fullCartClients =
              validClients.where((c) => c.fullCart == true).length;

          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'نشط (آخر 7 أيام)',
                        activeClients.toString(),
                        Icons.online_prediction,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'عربة ممتلئة',
                        fullCartClients.toString(),
                        Icons.shopping_cart,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'مع ملاحظات',
                        _clientNotes.length.toString(),
                        Icons.note,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
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
          hintText: 'ابحث بالاسم، الهاتف، المنطقة، الفئة...',
          hintStyle: TextStyle(color: darkBlueColor, fontSize: 12),
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

  void _openFullScreenImage(
      BuildContext context, String imageUrl, String clientName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(
            imageUrl: imageUrl,
            clientName: clientName,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    final hasNote = _clientNotes.containsKey(client.uid);
    final isActive = client.lastTokenUpdate != null &&
        DateTime.now().difference(client.lastTokenUpdate!).inDays < 7;

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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: GestureDetector(
                      onTap: client.imageUrl != null &&
                              client.imageUrl!.isNotEmpty
                          ? () => _openFullScreenImage(
                              context, client.imageUrl!, client.businessName)
                          : null,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: client.imageUrl != null &&
                                client.imageUrl!.isNotEmpty
                            ? NetworkImage(client.imageUrl!)
                            : null,
                        child:
                            client.imageUrl == null || client.imageUrl!.isEmpty
                                ? const Icon(Icons.person, size: 30)
                                : null,
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  if (client.fullCart == true)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClientDetails(client),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: primaryColor,
                    onPressed: () => _navigateToChat(client),
                    tooltip: 'بدء محادثة',
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _clientNotes[client.uid]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                'انضم ${_formatRelativeTime(client.dateCreated)}',
                Colors.blue,
              ),
              _buildInfoChip(
                Icons.access_time,
                'نشاط ${_formatRelativeTime(client.lastTokenUpdate)}',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails(ClientModel client) {
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
  final String? clientNote;
  final VoidCallback onClientUpdated;
  final Function(String) onNoteUpdated;

  const ClientDetailsDialog({
    super.key,
    required this.client,
    this.clientNote,
    required this.onClientUpdated,
    required this.onNoteUpdated,
  });

  @override
  State<ClientDetailsDialog> createState() => _ClientDetailsDialogState();
}

class _ClientDetailsDialogState extends State<ClientDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _businessNameController;
  late TextEditingController _categoryController;
  late TextEditingController _phoneController;
  late TextEditingController _secondPhoneController;
  late TextEditingController _governmentController;
  late TextEditingController _townController;
  late TextEditingController _areaController;
  late TextEditingController _addressTypedController;
  late TextEditingController _noteController;
  late TabController _tabController;

  bool _isEditing = false;
  bool _isUpdating = false;
  bool _isUploadingImage = false;
  String? _newImageUrl;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClientOrders();
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
        TextEditingController(text: widget.client.addressTyped);
    _noteController = TextEditingController(text: widget.clientNote ?? '');
  }

  Future<void> _loadClientOrders() async {
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .doc(widget.client.uid)
          .collection('orders')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _orders = ordersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
      });
      debugPrint('Error loading orders: $e');
    }
  }

  Future<void> _saveNote() async {
    try {
      final noteText = _noteController.text.trim();

      if (noteText.isEmpty) {
        // Delete note
        await FirebaseFirestore.instance
            .collection('admin_data')
            .doc('client_notes')
            .update({widget.client.uid: FieldValue.delete()});
      } else {
        // Save note
        await FirebaseFirestore.instance
            .collection('admin_data')
            .doc('client_notes')
            .set(
          {widget.client.uid: noteText},
          SetOptions(merge: true),
        );
      }

      widget.onNoteUpdated(noteText);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملاحظة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الملاحظة: $e')),
      );
    }
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
      if (widget.client.imageUrl != null) {
        try {
          final Reference oldImageRef =
              FirebaseStorage.instance.refFromURL(widget.client.imageUrl ?? '');
          await oldImageRef.delete();
        } catch (e) {
          debugPrint('Could not delete old image: $e');
        }
      }

      final String fileName =
          'client_images/${widget.client.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;

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

  void _navigateToChat() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/ChatScreen',
      arguments: {
        'clientId': widget.client.uid,
        'clientData': {
          'businessName': widget.client.businessName,
          'imageUrl': widget.client.imageUrl,
          'phoneNumber': widget.client.phoneNumber,
          'category': widget.client.category,
          'government': widget.client.government,
          'town': widget.client.town,
          'area': widget.client.area,
        },
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'غير متوفر';
    return DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
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
                    onPressed: _navigateToChat,
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                    tooltip: 'بدء محادثة',
                  ),
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
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'المعلومات'),
                Tab(text: 'التقارير'),
                Tab(text: 'الطلبات'),
                Tab(text: 'الملاحظات'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildReportsTab(),
                  _buildOrdersTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            : widget.client.imageUrl != null
                                ? Image.network(
                                    widget.client.imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.person, size: 50),
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
                          border: Border.all(color: Colors.white, width: 2),
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
          _buildDetailField('اسم النشاط', _businessNameController, _isEditing),
          _buildDetailField('الفئة', _categoryController, _isEditing),
          _buildDetailField('رقم الهاتف الأول', _phoneController, _isEditing),
          _buildDetailField(
              'رقم الهاتف الثاني', _secondPhoneController, _isEditing),
          const Text(
            'العنوان',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailField('المحافظة', _governmentController, _isEditing),
          _buildDetailField('المدينة', _townController, _isEditing),
          _buildDetailField('المنطقة', _areaController, _isEditing),
          _buildDetailField(
              'العنوان المكتوب', _addressTypedController, _isEditing),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (widget.client.geoLocation != null) {
                openMap(
                  widget.client.geoLocation!.latitude,
                  widget.client.geoLocation!.longitude,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('لا يوجد موقع جغرافي لهذا العميل')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'عرض الموقع على الخريطة',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportCard(
            'حالة التسجيل',
            widget.client.registrationComplete == true ? 'مكتمل' : 'غير مكتمل',
            widget.client.registrationComplete == true
                ? Colors.green
                : Colors.orange,
            Icons.how_to_reg,
          ),
          _buildReportCard(
            'حالة العربة',
            widget.client.fullCart == true ? 'ممتلئة' : 'فارغة',
            widget.client.fullCart == true ? Colors.orange : Colors.grey,
            Icons.shopping_cart,
          ),
          _buildReportCard(
            'تاريخ الانضمام',
            _formatDateTime(widget.client.dateCreated),
            Colors.blue,
            Icons.calendar_today,
          ),
          _buildReportCard(
            'آخر نشاط',
            _formatDateTime(widget.client.lastTokenUpdate),
            Colors.green,
            Icons.access_time,
          ),
          _buildReportCard(
            'آخر تحديث للبيانات',
            _formatDateTime(widget.client.lastUpdated),
            Colors.purple,
            Icons.update,
          ),
          if (widget.client.cartStatusUpdatedAt != null)
            _buildReportCard(
              'آخر تحديث لحالة العربة',
              _formatDateTime(widget.client.cartStatusUpdatedAt),
              Colors.orange,
              Icons.shopping_cart_checkout,
            ),
          if (widget.client.lastReminderSentAt != null)
            _buildReportCard(
              'آخر تذكير مرسل',
              _formatDateTime(widget.client.lastReminderSentAt),
              Colors.red,
              Icons.notification_important,
            ),
          _buildReportCard(
            'عدد الأجهزة',
            widget.client.totalDevices?.toString() ?? '0',
            Colors.teal,
            Icons.devices,
          ),
          if (widget.client.lastCartReminder != null)
            _buildReportCard(
              'آخر تذكير بالعربة',
              widget.client.lastCartReminder!,
              Colors.amber,
              Icons.alarm,
            ),
          const SizedBox(height: 16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملاحظات حول العميل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _noteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'أضف ملاحظاتك حول هذا العميل...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ الملاحظة',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate order statistics
    int totalOrders = _orders.length;
    int completedOrders =
        _orders.where((o) => o['state'] == 'تم التوصيل').length;
    double totalRevenue = _orders.fold(0.0, (sum, order) {
      final total = order['totalWithOffer'] ?? order['total'] ?? 0;
      return sum + (total is int ? total.toDouble() : total);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'إحصائيات الطلبات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOrderStat('إجمالي الطلبات', totalOrders.toString(),
                        Icons.shopping_cart, Colors.blue),
                    _buildOrderStat('المكتملة', completedOrders.toString(),
                        Icons.check_circle, Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOrderStat(
                  'إجمالي الإيرادات',
                  '${totalRevenue.toStringAsFixed(0)} ج.م',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'سجل الطلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Orders List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return _buildOrderCard(order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderDate =
        order['date'] != null ? (order['date'] as Timestamp).toDate() : null;
    final doneDate = order['doneAt'] != null
        ? (order['doneAt'] as Timestamp).toDate()
        : null;
    final orderCode = order['orderCode']?.toString() ?? 'N/A';
    final itemCount = order['itemCount'] ?? 0;
    final total = order['total'] ?? 0;
    final totalWithOffer = order['totalWithOffer'] ?? total;
    final state = order['state'] ?? 'قيد المعالجة';
    final note = order['note']?.toString() ?? '';
    final products = order['products'] as List<dynamic>? ?? [];

    Color stateColor;
    IconData stateIcon;
    switch (state) {
      case 'تم التوصيل':
        stateColor = Colors.green;
        stateIcon = Icons.check_circle;
        break;
      case 'قيد التوصيل':
        stateColor = Colors.orange;
        stateIcon = Icons.local_shipping;
        break;
      case 'ملغي':
        stateColor = Colors.red;
        stateIcon = Icons.cancel;
        break;
      default:
        stateColor = Colors.blue;
        stateIcon = Icons.pending;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(stateIcon, color: stateColor),
        ),
        title: Row(
          children: [
            Text(
              'طلب #$orderCode',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stateColor.withOpacity(0.3)),
              ),
              child: Text(
                state,
                style: TextStyle(
                  fontSize: 11,
                  color: stateColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  orderDate != null ? _formatDateTime(orderDate) : 'غير محدد',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$itemCount منتج',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.payments, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$totalWithOffer ج.م',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalWithOffer < total) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          // Order Details
          if (note.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (doneDate != null) ...[
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'تم التوصيل في: ${_formatDateTime(doneDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'المنتجات:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Products List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, idx) {
              final item = products[idx] as Map<String, dynamic>;
              final product = item['product'] as Map<String, dynamic>?;
              final quantity = item['controller'] ?? 0;

              if (product == null) return const SizedBox.shrink();

              final productName = product['name'] ?? 'منتج غير معروف';
              final productPrice = product['isOnSale'] == true
                  ? product['offerPrice']
                  : product['price'];
              final productImage = product['imageUrl'];
              final itemTotal = (productPrice ?? 0) * quantity;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Product Image
                    if (productImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          productImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'الكمية: $quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$itemTotal ج.م',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Order Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalWithOffer ج.م',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (totalWithOffer < total)
                      Text(
                        'كان $total ج.م',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    _tabController.dispose();
    _businessNameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _secondPhoneController.dispose();
    _governmentController.dispose();
    _townController.dispose();
    _areaController.dispose();
    _addressTypedController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
