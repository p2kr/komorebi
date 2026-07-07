import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(obfuscate: true, useConstantCase: true, allowOptionalFields: true)
abstract class Env {
  @EnviedField()
  static final String malClientId = _Env.malClientId;

  @EnviedField()
  static final String malClientSecret = _Env.malClientSecret;
}
