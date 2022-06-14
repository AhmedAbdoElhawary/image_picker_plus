import 'dart:io';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///** Maybe you will face a problem when you trying to run those lines,
///** error like "The Android Gradle plugin supports only Kotlin Gradle plugin version 1.3.40 and higher.".
///** You can solve it with replacing all lines in dependencies in (android\build.gradle)
/*
  replace it from ---->
    dependencies {
        classpath 'com.android.tools.build:gradle:7.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        }

  To ----------------->
        classpath 'com.google.gms:google-services:4.3.10'
        classpath 'com.android.tools.build:gradle:4.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom gallery display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      body: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              instagramButton1(context),
              instagramButton2(context),
              instagramButton3(context),
              normalButton1(context),
              normalButton2(context),
              normalButton3(context),
            ]),
      ),
    );
  }

  ElevatedButton normalButton3(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CustomGallery.normalDisplay(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
                childAspectRatio: .5,
              ),
              moveToPage: moveToPage,
            ),
          ),
        );
      },
      child: const Text("Normal 3 display"),
    );
  }

  ElevatedButton normalButton2(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CustomGallery.normalDisplay(
              enableVideo: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
              ),
              moveToPage: moveToPage,
            ),
          ),
        );
      },
      child: const Text("Normal 2 display"),
    );
  }

  ElevatedButton normalButton1(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CustomGallery.normalDisplay(
              enableCamera: true,
              enableVideo: true,
              moveToPage: moveToPage,
            ),
          ),
        );
      },
      child: const Text("Normal display"),
    );
  }

  ElevatedButton instagramButton3(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CustomGallery.instagramDisplay(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
                childAspectRatio: .5,
              ),
              moveToPage: moveToPage,
            ),
          ),
        );
      },
      child: const Text("Instagram 3 display"),
    );
  }

  ElevatedButton instagramButton2(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CustomGallery.instagramDisplay(
              enableVideo: true,
              enableCamera: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
              ),
              moveToPage: moveToPage,
            ),
          ),
        );
      },
      child: const Text("Instagram 2 display"),
    );
  }

  ElevatedButton instagramButton1(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => CustomGallery.instagramDisplay(
                enableCamera: true,
                enableVideo: true,
                moveToPage: moveToPage)));
      },
      child: const Text("Instagram display"),
    );
  }

  Future<void> moveToPage(SelectedImageDetails details) async {
    await Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => SelectedImage(
            selectedFiles: details.selectedFiles != null
                ? details.selectedFiles!
                : [details.selectedFile],
            aspectRatio: details.aspectRatio)));
  }
}

class SelectedImage extends StatelessWidget {
  final List<File> selectedFiles;
  final double aspectRatio;
  const SelectedImage(
      {Key? key, required this.selectedFiles, required this.aspectRatio})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      body: ListView.builder(
        itemBuilder: (context, index) {
          File image = selectedFiles[index];
          return SizedBox(width: double.infinity, child: Image.file(image));
        },
        itemCount: selectedFiles.length,
      ),
    );
  }
}
