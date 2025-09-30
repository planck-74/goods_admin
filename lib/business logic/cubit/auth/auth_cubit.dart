import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  static final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());

    if (email.isEmpty || password.isEmpty) {
      emit(AuthError('يجب إدخال كلاً من البريد وكلمة السر'));
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } on SocketException {
      emit(
          AuthError('لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.'));
    } catch (e) {
      emit(AuthError('حدث خطأ غير متوقع: $e'));
    }
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    if (e.code == 'user-not-found') {
      emit(AuthError('المستخدم غير موجود'));
    } else {
      emit(AuthError('هناك خطأ بالبريد أو كلمة المرور'));
    }
  }
}
