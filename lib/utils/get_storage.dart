import 'package:get_storage/get_storage.dart';

class Helper {
  static final _storage = GetStorage();

   static Future<void> setUserCredential(String id) async {
    try {
      await _storage.write("id", id);
    } catch (e) {
      print("Error $e");
    }
  }

  static String? getUserCredential() {
    try {
      return _storage.read<String>("id");
    } catch (e) {
      print("Error $e");
    }
    return null;
  }
}