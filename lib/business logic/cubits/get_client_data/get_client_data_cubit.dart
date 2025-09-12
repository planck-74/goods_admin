import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_state.dart';
import 'package:goods_admin/data/models/client_model.dart';

class GetClientDataCubit extends Cubit<GetClientDataState> {
  GetClientDataCubit() : super(GetClientDataInitial());
  Map<String, dynamic>? client;

  Future<void> getClientData() async {
    try {
      emit(GetClientDataLoading());

      QuerySnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance.collection('clients').get();

      List<ClientModel> clients = documentSnapshot.docs
          .map((e) => ClientModel.fromMap(e.data()))
          .toList();
      emit(GetClientDataSuccess(clients));
    } catch (e) {
      emit(GetClientDataError(e.toString()));
    }
  }

  Future<List<QueryDocumentSnapshot>> searchClientsByName(
      String searchQuery) async {
    CollectionReference clientsRef =
        FirebaseFirestore.instance.collection('clients');

    QuerySnapshot querySnapshot = await clientsRef
        .where('businessName', isGreaterThanOrEqualTo: searchQuery)
        .where('businessName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
        .get();

    return querySnapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> searchClientsComprehensive(
      String query) async {
    if (query.isEmpty) return [];

    String searchLower = query.toLowerCase();

    try {
      // Get all clients first (since Firestore doesn't support OR queries across different fields efficiently)
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('clients').get();

      // Filter clients based on multiple fields
      List<QueryDocumentSnapshot> filteredDocs = snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check business name
        String businessName =
            (data['businessName'] ?? '').toString().toLowerCase();

        // Check phone numbers
        String phoneNumber =
            (data['phoneNumber'] ?? '').toString().toLowerCase();
        String secondPhoneNumber =
            (data['secondPhoneNumber'] ?? '').toString().toLowerCase();

        // Check address fields
        String government = (data['government'] ?? '').toString().toLowerCase();
        String town = (data['town'] ?? '').toString().toLowerCase();
        String area = (data['area'] ?? '').toString().toLowerCase();
        String addressTyped =
            (data['addressTyped'] ?? '').toString().toLowerCase();

        // Check category
        String category = (data['category'] ?? '').toString().toLowerCase();

        // Check if query matches any field
        return businessName.contains(searchLower) ||
            phoneNumber.contains(searchLower) ||
            secondPhoneNumber.contains(searchLower) ||
            government.contains(searchLower) ||
            town.contains(searchLower) ||
            area.contains(searchLower) ||
            addressTyped.contains(searchLower) ||
            category.contains(searchLower);
      }).toList();

      return filteredDocs;
    } catch (e) {
      debugPrint('Error in comprehensive search: $e');
      return [];
    }
  }
}
