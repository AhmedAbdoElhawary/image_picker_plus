import 'dart:io';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CustomGalleryPermissions.requestPermissionExtend();
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
    return Container(
      color: Colors.white,
      child: SafeArea(
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
              appTheme: AppTheme(
                  focusColor: Colors.white, primaryColor: Colors.black),
              tabsNames: TabsNames(
                videoName: "فيديو",
                galleryName: "المعرض",
                deletingName: "حذف",
                clearImagesName: "الغاء الصور المحدده",
                limitingName: "اقصي حد للصور هو 10",
              ),
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
              enableVideo: true,
              enableCamera: true,
              appTheme: AppTheme(
                  focusColor: Colors.white, primaryColor: Colors.black),
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
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                CustomGallery.instagramDisplay(moveToPage: moveToPage),
          ),
        );
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
