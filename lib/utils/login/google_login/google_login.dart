import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/login/lib/login_status.dart';
import 'package:SombaTeka/utils/login/lib/login_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLogin extends LoginSystem {
  GoogleSignIn? _googleSignIn;

  @override
  void init() {
    _googleSignIn = GoogleSignIn(
      scopes: ["profile", "email"],
    );
  }

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());
      GoogleSignInAccount? googleSignIn = await _googleSignIn?.signIn();
      if (googleSignIn == null) {
        emit(MFail("loginCancelledByUser".translate(Constant.navigatorKey.currentContext!)));
        return null;
      }

      GoogleSignInAuthentication? googleAuth =
          await googleSignIn.authentication;

      AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(authCredential);
      emit(MSuccess());

      return userCredential;
    } catch (e) {
      emit(MFail(e.toString()));
      return null; // or rethrow if you really want to handle it in UI
    }
  }


  void signOut() async {
    if (await _googleSignIn?.isSignedIn() ?? false) {
      _googleSignIn?.signOut();
    }
  }

  @override
  void onEvent(MLoginState state) {}
}
