import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_state.dart';
import 'package:goods_admin/data/models/client_model.dart';

class GetClientDataCubit extends Cubit<GetClientDataState> {
  GetClientDataCubit() : super(GetClientDataInitial());
  Map<String, dynamic>? client;

  Future<void> getClientData() async {
    try {
      // Emit loading state
      emit(GetClientDataLoading());

      // Fetch the Client data from Firestore using the UID
      QuerySnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance.collection('clients').get();

      List<ClientModel> clients = documentSnapshot.docs
          .map((e) => ClientModel.fromMap(e.data()))
          .toList();
      print('clients: ${clients.length}');
      emit(GetClientDataSuccess(clients));
    } catch (e) {
      // Emit error state if something goes wrong
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
}
