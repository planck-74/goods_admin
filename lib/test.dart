import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
Future<void> unifyDocIds() async {
  try {
    CollectionReference productsCollection = _firestore.collection('products');
    QuerySnapshot productsSnapshot = await productsCollection.get();

    WriteBatch batch = _firestore.batch();
    int operations = 0;

    for (QueryDocumentSnapshot productDoc in productsSnapshot.docs) {
      String productId = productDoc['productId'];
      if (productDoc.id == productId) continue;

      DocumentReference newDocRef = productsCollection.doc(productId);

      batch.set(newDocRef, productDoc.data() as Map<String, dynamic>);
      batch.delete(productDoc.reference);
      operations += 2;

      // Firestore يسمح بحد أقصى 500 عملية في كل batch
      if (operations >= 490) {
        await batch.commit();
        batch = _firestore.batch();
        operations = 0;
      }
    }

    if (operations > 0) {
      await batch.commit();
    }

    print('DocIds unified successfully for all documents!');
  } catch (e) {
    print('Error while unifying docIds: $e');
  }
}

  Future<void> unifySingleDocId(String currentDocId) async {
    try {
      CollectionReference productsCollection =
          _firestore.collection('products');

      // جيب المستند الحالي بناءً على الـ docId الفعلي
      DocumentSnapshot productDoc =
          await productsCollection.doc(currentDocId).get();

      if (!productDoc.exists) {
        print('No document found with docId: $currentDocId');
        return;
      }

      String productId = productDoc['productId'];

      // لو أصلاً موحّد، لا تعمل شيء
      if (currentDocId == productId) {
        print('Already unified: $currentDocId');
        return;
      }

      DocumentReference newDocRef = productsCollection.doc(productId);

      await newDocRef.set(productDoc.data() as Map<String, dynamic>);
      await productDoc.reference.delete();

      print('DocId unified: from $currentDocId to $productId');
    } catch (e) {
      print('Error while unifying docId from $currentDocId: $e');
    }
  }
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// void main() async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   FirestoreService firestoreService = FirestoreService();
//   await firestoreService.unifySingleDocId('0KcuSUNmvOa6tzuzj7m6');
// }
