import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> _refreshSearchResults() async {
    if (_searchController.text.isNotEmpty) {
      await _searchClients(_searchController.text);
    } else {
      context.read<GetClientDataCubit>().getClientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text('العملاء', style: TextStyle(color: kWhiteColor)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSearchField(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? RefreshIndicator(
                        onRefresh: _refreshSearchResults,
                        child: _buildClientList(_searchResults!),
                      )
                    : BlocBuilder<GetClientDataCubit, GetClientDataState>(
                        builder: (context, state) {
                          if (state is GetClientDataLoading) {
                            return const Center(
                                child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ));
                          } else if (state is GetClientDataSuccess) {
                            return RefreshIndicator(
                              onRefresh: _refreshSearchResults,
                              child: state.clients.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'لا يوجد عملاء',
                                        style: TextStyle(
                                            color: kDarkBlueColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : _buildClientList(state.clients),
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

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        cursorHeight: 25,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث عن عميل',
          hintStyle: TextStyle(color: kDarkBlueColor, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
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
            onTap: () {
              // showEditClientsheet(context, client);
            },
            child: _buildClientCard(client),
          ),
        );
      },
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                client.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildClientDetails(client),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails(ClientModel client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          client.businessName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            openMap(client.geoPoint.latitude, client.geoPoint.longitude);
          },
          child: Text(
            client.address,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${client.phoneNumber} : ${client.secondPhoneNumber}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}

// /// Bottom Sheet to edit client details (unchanged)
// void showEditClientsheet(BuildContext context, ClientModel client) {
//   final TextEditingController nameController =
//       TextEditingController(text: client.name);
//   final TextEditingController manufacturerController =
//       TextEditingController(text: client.address);
//   final TextEditingController sizeController =
//       TextEditingController(text: client.businessName);
//   final TextEditingController packageController =
//       TextEditingController(text: client.category);
//   final TextEditingController noteController =
//       TextEditingController(text: client.phoneNumber.toString());
//   final TextEditingController salesCountController =
//       TextEditingController(text: client.secondPhoneNumber.toString());

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
//     ),
//     builder: (context) => Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//         left: 16,
//         right: 16,
//         top: 16,
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "تعديل المنتج",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(
//                 labelText: "اسم المنتج",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: sizeController,
//               decoration: const InputDecoration(
//                 labelText: "الحجم",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: manufacturerController,
//               decoration: const InputDecoration(
//                 labelText: "الشركة المصنعة",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: packageController,
//               decoration: const InputDecoration(
//                 labelText: "العبوة",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const SizedBox(height: 10),
//             TextField(
//               controller: noteController,
//               decoration: const InputDecoration(
//                 labelText: "ملاحظات",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   style:
//                       ElevatedButton.styleFrom(backgroundColor: primaryColor),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text(
//                     "حفظ",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style:
//                       ElevatedButton.styleFrom(backgroundColor: Colors.white),
//                   child: const Text("إلغاء"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     ),
//   );
// }
