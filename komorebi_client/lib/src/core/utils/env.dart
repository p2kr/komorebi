import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(obfuscate: true, useConstantCase: true, allowOptionalFields: true)
abstract class Env {
  @EnviedField()
  static final String malClientId = _Env.malClientId;

  @EnviedField(defaultValue: "")
  static final String malClientSecret = _Env.malClientSecret;

  @EnviedField()
  static final int anilistClientId = _Env.anilistClientId;

  @EnviedField()
  static final String anilistClientSecret = _Env.anilistClientSecret;
}
