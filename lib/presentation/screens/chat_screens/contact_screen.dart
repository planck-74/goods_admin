import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:intl/intl.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<List<Map<String, dynamic>>> _buildChatList(
    List<QueryDocumentSnapshot> chatDocs,
  ) async {
    final List<Map<String, dynamic>> chatList = [];

    for (var doc in chatDocs) {
      final docData = doc.data() as Map<String, dynamic>;
      final String clientId = doc.id;

      // Ensure we have the needed fields
      if (!docData.containsKey('lastMessage') ||
          !docData.containsKey('lastMessageTime')) {
        continue;
      }

      final String lastMessage = docData['lastMessage'] ?? '';
      final Timestamp? timestamp = docData['lastMessageTime'] as Timestamp?;
      if (timestamp == null) continue;

      // Extract unreadCount
      final int unreadCount = docData['unreadCount'] ?? 0;

      // Fetch client info
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

    // Sort by lastMessageTime descending
    chatList.sort((a, b) {
      final Timestamp t1 = a['timestamp'] as Timestamp;
      final Timestamp t2 = b['timestamp'] as Timestamp;
      return t2.compareTo(t1);
    });

    return chatList;
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
                return const Center(child: Text('لا توجد محادثات بعد'));
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

                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                clientData['imageUrl'] ?? '',
                              ),
                              radius: 30,
                            ),
                            title: Text(
                              clientData['businessName'] ?? 'اسم غير معروف',
                            ),
                            subtitle: Text(
                              lastMessage,
                              style: const TextStyle(color: darkBlueColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formattedTime),
                                const SizedBox(width: 8),
                                // Red dot with unread count
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
