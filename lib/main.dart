import 'package:ecommerce_app/app.dart';
import 'package:flutter/material.dart';

import 'core/network/dio_client.dart';
import 'core/storage/preference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferenceService = await PreferenceService.init();
  final dioClient = DioClient(preferenceService: preferenceService);
  runApp(MyApp(dioClient: dioClient, preferenceService: preferenceService));
}