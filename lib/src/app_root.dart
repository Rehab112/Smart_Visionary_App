import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend_app/views/home_view.dart';

class AppRoot extends StatelessWidget {
  final CameraDescription camera;

  const AppRoot({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeView(
        camera: camera,
      ),
    );
  }
}
