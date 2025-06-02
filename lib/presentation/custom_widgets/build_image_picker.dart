import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/image_picker_cubit/image_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/image_picker_cubit/image_state.dart';

Widget buildImagePicker({
  required double screenHeight,
  required BuildContext context,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 72,
            backgroundColor: Theme.of(context).primaryColor,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Theme.of(context).primaryColor,
              child: CircleAvatar(
                  backgroundColor: Theme.of(context).hoverColor,
                  radius: 100,
                  child: BlocBuilder<ImageCubit, ImageState>(
                    builder: (context, state) {
                      if (state is ImageLoading) {
                        const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (state is ImageLoaded) {
                        return ClipOval(
                          child: Image.file(
                            state.image,
                            fit: BoxFit.cover,
                            width: 200,
                            height: 200,
                          ),
                        );
                      }
                      return Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.grey.shade400,
                        size: 24,
                      );
                    },
                  )),
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
      ],
    ),
  );
}
