import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/controller/controllers_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/auth/auth_cubit.dart';
import 'package:goods_admin/presentation/backgrounds/otp_background.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_outlinedButton.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_textfield.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';
import 'package:goods_admin/presentation/screens/home.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final controllersCubit = context.read<ControllersCubit>();

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          snackBarErrors(context, state.message);
        } else if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
          showSuccessMessage(context, "تم تسجيل الدخول بنجاح!");
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const BuildBackground(),
            Column(
              children: [
                SizedBox(height: screenHeight * 0.3),
                _buildEmailField(screenWidth, controllersCubit),
                _buildPasswordField(screenWidth, controllersCubit),
                const SizedBox(height: 24),
                _buildSignInButton(screenWidth, context, controllersCubit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(
      double screenWidth, ControllersCubit controllersCubit) {
    return customTextField(
      controller: controllersCubit.email,
      width: screenWidth,
      labelText: 'البريد الالكتروني',
      validationText: 'أدخل البريد الالكتروني',
      context: context,
    );
  }

  Widget _buildPasswordField(
      double screenWidth, ControllersCubit controllersCubit) {
    return customTextField(
      controller: controllersCubit.password,
      width: screenWidth,
      labelText: 'كلمة السر',
      validationText: 'أدخل كلمة السر',
      context: context,
    );
  }

  Widget _buildSignInButton(double screenWidth, BuildContext context,
      ControllersCubit controllersCubit) {
    return customOutlinedButton(
      width: screenWidth * 0.3,
      height: 32,
      context: context,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const CircularProgressIndicator();
          }
          return const Text(
            'تسجيل الدخول',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
      onPressed: () {
        final email = controllersCubit.email.text.trim();
        final password = controllersCubit.password.text.trim();

        context.read<AuthCubit>().signIn(email, password).then((_) {
          controllersCubit.email.clear();
          controllersCubit.password.clear();
        });
      },
    );
  }
}
