import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class Locations extends StatefulWidget {
  const Locations({super.key});

  @override
  State<Locations> createState() => _LocationsState();
}

class _LocationsState extends State<Locations> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        const Text(
          'المحافظات والمدن والمناطق',
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('admin_data')
            .doc('locations')
            .collection('governments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("خطأ: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final governments = snapshot.data!.docs;

          if (governments.isEmpty) {
            return const Center(child: Text('لا توجد محافظات.'));
          }

          return ListView.builder(
            itemCount: governments.length,
            itemBuilder: (context, index) {
              final governmentDoc = governments[index];
              final governmentName = governmentDoc.id;

              return FutureBuilder<QuerySnapshot>(
                future: governmentDoc.reference.collection('cities').get(),
                builder: (context, citySnapshot) {
                  List<Widget> cityWidgets = [];

                  if (citySnapshot.connectionState == ConnectionState.waiting) {
                    cityWidgets.add(const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  } else if (citySnapshot.hasData &&
                      citySnapshot.data!.docs.isNotEmpty) {
                    cityWidgets = citySnapshot.data!.docs.map((cityDoc) {
                      final cityName = cityDoc.id;

                      return FutureBuilder<QuerySnapshot>(
                        future: cityDoc.reference.collection('areas').get(),
                        builder: (context, areaSnapshot) {
                          List<Widget> areaWidgets = [];

                          if (areaSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            areaWidgets.add(const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ));
                          } else if (areaSnapshot.hasData &&
                              areaSnapshot.data!.docs.isNotEmpty) {
                            areaWidgets =
                                areaSnapshot.data!.docs.map((areaDoc) {
                              return ListTile(
                                title: Text(
                                  areaDoc.id,
                                  style: const TextStyle(
                                      fontSize: 14, fontFamily: 'Cairo'),
                                ),
                                leading:
                                    const Icon(Icons.location_on, size: 18),
                              );
                            }).toList();
                          } else {
                            areaWidgets.add(const ListTile(
                              title: Text('لا توجد مناطق',
                                  style: TextStyle(
                                      fontSize: 14, fontFamily: 'Cairo')),
                            ));
                          }

                          return ExpansionTile(
                            title: Text(
                              cityName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Cairo'),
                            ),
                            children: areaWidgets,
                          );
                        },
                      );
                    }).toList();
                  } else {
                    cityWidgets.add(const ListTile(
                      title: Text('لا توجد مدن',
                          style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
                    ));
                  }

                  return ExpansionTile(
                    title: Text(
                      governmentName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    children: cityWidgets,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
