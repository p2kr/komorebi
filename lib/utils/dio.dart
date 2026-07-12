import 'package:dio/dio.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

Dio getDioWithLogger([BaseOptions? options]) => Dio(options)
  ..interceptors.add(
    TalkerDioLogger(talker: talker, settings: const TalkerDioLoggerSettings()),
  );
