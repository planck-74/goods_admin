import 'package:flutter/material.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_container.dart';

class AddLocation extends StatefulWidget {
  const AddLocation({super.key});

  @override
  State<AddLocation> createState() => _AddLocationState();
}

class _AddLocationState extends State<AddLocation> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: customAppBar(
          context,
          const Text(
            'إضافة موقع',
            style: TextStyle(color: kWhiteColor),
          )),
      body: Column(
        children: [
          customContainer(
              context: context,
              onTap: () => Navigator.pushNamed(context, '/Locations'),
              screenWidth: screenWidth,
              text: 'المواقع'),
          customContainer(
              context: context,
              onTap: () => Navigator.pushNamed(context, '/AddGovernment'),
              screenWidth: screenWidth,
              text: 'إضافة محافظة'),
          customContainer(
              context: context,
              onTap: () => Navigator.pushNamed(context, '/AddCity'),
              screenWidth: screenWidth,
              text: 'إضافة مدينة'),
          customContainer(
              context: context,
              onTap: () => Navigator.pushNamed(context, '/AddArea'),
              screenWidth: screenWidth,
              text: 'إضافة منطقة')
        ],
      ),
    );
  }
}
