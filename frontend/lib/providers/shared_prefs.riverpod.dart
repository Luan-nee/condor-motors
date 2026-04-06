import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_prefs.riverpod.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPrefs(SharedPrefsRef ref) {
  // Se debe sobreescribir en el ProviderScope de main.dart una vez inicializado
  throw UnimplementedError('SharedPreferences no ha sido inicializado y sobreescrito');
}
