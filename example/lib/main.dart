import 'dart:io';

import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
              sendRequestFunction: moveToPage,
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
              tabsTexts: TabsTexts(
                videoText: "فيديو",
                galleryText: "المعرض",
                deletingText: "حذف",
                clearImagesText: "الغاء الصور المحدده",
                limitingText: "اقصي حد للصور هو 10",
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
              ),
              sendRequestFunction: moveToPage,
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
              sendRequestFunction: moveToPage,
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
              sendRequestFunction: moveToPage,
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
              sendRequestFunction: moveToPage,
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
                CustomGallery.instagramDisplay(sendRequestFunction: moveToPage),
          ),
        );
      },
      child: const Text("Instagram display"),
    );
  }

  Future<void> moveToPage(SelectedImagesDetails details) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          if (details.isThatImage) {
            return DisplayImages(
                selectedFiles: details.selectedFiles != null
                    ? details.selectedFiles!
                    : [details.selectedFile],
                details: details,
                aspectRatio: details.aspectRatio);
          } else {
            return DisplayVideo(
                video: details.selectedFile, aspectRatio: details.aspectRatio);
          }
        },
      ),
    );
  }
}

class DisplayImages extends StatelessWidget {
  final List<File> selectedFiles;
  final double aspectRatio;
  final SelectedImagesDetails details;
  const DisplayImages({
    Key? key,
    required this.details,
    required this.selectedFiles,
    required this.aspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image')),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return SizedBox(
              width: double.infinity, child: Image.file(selectedFiles[index]));
        },
        itemCount: selectedFiles.length,
      ),
    );
  }
}

class DisplayVideo extends StatefulWidget {
  final File video;
  final double aspectRatio;
  const DisplayVideo({
    Key? key,
    required this.video,
    required this.aspectRatio,
  }) : super(key: key);

  @override
  State<DisplayVideo> createState() => _DisplayVideoState();
}

class _DisplayVideoState extends State<DisplayVideo> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
