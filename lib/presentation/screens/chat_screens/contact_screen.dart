import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/client_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/screens/chat_screens/full_screen_image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<List<Map<String, dynamic>>> _buildChatList(
    List<QueryDocumentSnapshot> chatDocs,
  ) async {
    final List<Map<String, dynamic>> chatList = [];

    for (var doc in chatDocs) {
      final docData = doc.data() as Map<String, dynamic>;
      final String clientId = doc.id;

      if (!docData.containsKey('lastMessage') ||
          !docData.containsKey('lastMessageTime')) {
        continue;
      }

      final String lastMessage = docData['lastMessage'] ?? '';
      final Timestamp? timestamp = docData['lastMessageTime'] as Timestamp?;
      if (timestamp == null) continue;

      final int unreadCount = docData['unreadCount'] ?? 0;

      final clientSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .get();
      if (!clientSnapshot.exists) continue;

      final Map<String, dynamic> clientData = clientSnapshot.data() ?? {};

      chatList.add({
        'clientId': clientId,
        'clientData': clientData,
        'lastMessage': lastMessage,
        'timestamp': timestamp,
        'unreadCount': unreadCount,
      });
    }

    chatList.sort((a, b) {
      final Timestamp t1 = a['timestamp'] as Timestamp;
      final Timestamp t2 = b['timestamp'] as Timestamp;
      return t2.compareTo(t1);
    });

    return chatList;
  }

  void _showStartChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const StartNewChatDialog(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        const Text(
          'المحادثات',
          style: TextStyle(color: whiteColor),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartChatDialog(context),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'بدء محادثة جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').snapshots(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final chatDocs = chatSnapshot.data?.docs ?? [];
              if (chatDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد محادثات بعد',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على الزر في الأسفل لبدء محادثة جديدة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _buildChatList(
                  chatDocs.cast<QueryDocumentSnapshot>(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد محادثات بعد'));
                  }

                  final chatList = snapshot.data!;

                  return ListView.builder(
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      final chat = chatList[index];
                      final clientData =
                          chat['clientData'] as Map<String, dynamic>;
                      final clientId = chat['clientId'] as String;
                      final lastMessage = chat['lastMessage'] as String;
                      final timestamp = chat['timestamp'] as Timestamp;
                      final formattedTime =
                          DateFormat('hh:mm a').format(timestamp.toDate());
                      final imageUrl = clientData['imageUrl'] ?? '';
                      final clientName =
                          clientData['businessName'] ?? 'اسم غير معروف';

                      return Column(
                        children: [
                          ListTile(
                            leading: GestureDetector(
                              onTap: imageUrl.isNotEmpty
                                  ? () => _openFullScreenImage(
                                      context, imageUrl, clientName)
                                  : null,
                              child: Hero(
                                tag: 'client_image_$clientId',
                                child: CircleAvatar(
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  radius: 30,
                                  child: imageUrl.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              ),
                            ),
                            title: Text(clientName),
                            subtitle: Text(
                              lastMessage,
                              style: const TextStyle(color: darkBlueColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formattedTime),
                                const SizedBox(width: 8),
                                if (chat['unreadCount'] != null &&
                                    chat['unreadCount'] > 0)
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        chat['unreadCount'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              context
                                  .read<GetClientDataCubit>()
                                  .getClientData();
                              Navigator.pushNamed(
                                context,
                                '/ChatScreen',
                                arguments: {
                                  'clientId': clientId,
                                  'clientData': clientData,
                                },
                              );
                            },
                          ),
                          const Divider(
                            indent: 20,
                            endIndent: 20,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Full Screen Image Viewer Widget

// Dialog to select a client and start a new chat
class StartNewChatDialog extends StatefulWidget {
  const StartNewChatDialog({super.key});

  @override
  State<StartNewChatDialog> createState() => _StartNewChatDialogState();
}

class _StartNewChatDialogState extends State<StartNewChatDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ClientModel>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<GetClientDataCubit>().getClientData();
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
          .where((client) =>
              client.businessName.isNotEmpty && client.phoneNumber.isNotEmpty)
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
    }
  }

  void _startChatWithClient(ClientModel client) {
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
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
                    'اختر عميل لبدء المحادثة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن عميل...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _searchClients,
              ),
            ),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults != null
                      ? _buildClientList(_searchResults!)
                      : BlocBuilder<GetClientDataCubit, GetClientDataState>(
                          builder: (context, state) {
                            if (state is GetClientDataLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (state is GetClientDataSuccess) {
                              List<ClientModel> validClients = state.clients
                                  .where((client) =>
                                      client.businessName.isNotEmpty &&
                                      client.phoneNumber.isNotEmpty)
                                  .toList();
                              return _buildClientList(validClients);
                            } else if (state is GetClientDataError) {
                              return Center(
                                  child: Text('Error: ${state.message}'));
                            }
                            return const SizedBox();
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(List<ClientModel> clients) {
    if (clients.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد عملاء',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        ClientModel client = clients[index];
        return ListTile(
          leading: GestureDetector(
            onTap: client.imageUrl != null && client.imageUrl!.isNotEmpty
                ? () => _openFullScreenImage(
                    context, client.imageUrl!, client.businessName)
                : null,
            child: CircleAvatar(
              radius: 25,
              backgroundImage:
                  client.imageUrl != null && client.imageUrl!.isNotEmpty
                      ? NetworkImage(client.imageUrl!)
                      : null,
              child: client.imageUrl == null || client.imageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
          ),
          title: Text(
            client.businessName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.category.isNotEmpty)
                Text(
                  client.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              Text(
                client.phoneNumber,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
          trailing: const Icon(Icons.chat_bubble_outline, color: primaryColor),
          onTap: () => _startChatWithClient(client),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
