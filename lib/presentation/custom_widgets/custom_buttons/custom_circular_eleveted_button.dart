import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_state.dart';

Widget customCircularElevatedButton(
    {required IconData icon,
    required BuildContext context,
    required Color backgroundColor,
    required Color iconColor,
    double? iconSize,
    required VoidCallback onPressed}) {
  return SizedBox(
    height: 50,
    width: 50,
    child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(0),
          backgroundColor: backgroundColor,
        ),
        onPressed: onPressed,
        child: BlocBuilder<FirestoreServicesCubit, FirestoreServicesState>(
          builder: (context, state) {
            if (state is FirestoreServicesLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            return Icon(
              icon,
              color: iconColor,
              size: iconSize ?? 32,
            );
          },
        )),
  );
}
