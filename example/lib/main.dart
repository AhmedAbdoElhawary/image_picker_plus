import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImagePickerPlusPermissions.requestPermissionExtend();
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
              button1(context),
              button2(context),
              button3(context),
              button4(context),
              button5(context),
              button6(context),
              button7(context),
            ]),
      ),
    );
  }

  ElevatedButton button1(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        SelectedImagesDetails? details = await ImagePickerPlus(context)
            .pickImage(source: ImageSource.gallery);
        if (details != null) await displayDetails(details);
      },
      child: const Text("Normal 1"),
    );
  }

  ElevatedButton button2(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickVideo(
          source: ImageSource.both,

          /// On long tap, it will be available.
          multiVideos: true,
          galleryDisplaySettings: GalleryDisplaySettings(
            gridDelegate: _sliverGridDelegate(),
          ),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Normal 2"),
    );
  }

  ElevatedButton button3(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickBoth(
          source: ImageSource.camera,

          /// On long tap, it will be available.
          multiSelection: true,

          /// When you make ImageSource from the camera these settings will be disabled because they belong to the gallery.
          galleryDisplaySettings: GalleryDisplaySettings(),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Normal 3"),
    );
  }

  ElevatedButton button4(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickBoth(
          source: ImageSource.both,

          /// On long tap, it will be available.
          multiSelection: true,
          galleryDisplaySettings: GalleryDisplaySettings(
            gridDelegate: _sliverGridDelegate(),
          ),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Normal 4"),
    );
  }

  ElevatedButton button5(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickBoth(
          source: ImageSource.both,

          /// On long tap, it will be available.
          multiSelection: true,

          galleryDisplaySettings: GalleryDisplaySettings(
            appTheme:
                AppTheme(focusColor: Colors.white, primaryColor: Colors.black),
            cropImage: true,
            showImagePreview: true,
          ),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Preview 1"),
    );
  }

  ElevatedButton button6(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickVideo(
          source: ImageSource.both,
          /// On long tap, it will be available.
          multiVideos: true,
          galleryDisplaySettings: GalleryDisplaySettings(
            tabsTexts: _tabsTexts(),
            appTheme:
                AppTheme(focusColor: Colors.white, primaryColor: Colors.black),
            cropImage: true,
            showImagePreview: true,
          ),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Preview 2"),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _sliverGridDelegate() {
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 1.7,
      mainAxisSpacing: 1.5,
      childAspectRatio: .5,
    );
  }

  TabsTexts _tabsTexts() {
    return TabsTexts(
      videoText: "فيديو",
      galleryText: "المعرض",
      deletingText: "حذف",
      clearImagesText: "الغاء الصور المحدده",
      limitingText: "اقصي حد للصور هو 10",
    );
  }

  ElevatedButton button7(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        ImagePickerPlus picker = ImagePickerPlus(context);
        SelectedImagesDetails? details = await picker.pickBoth(
          source: ImageSource.both,

          /// On long tap, it will be available.
          multiSelection: true,

          galleryDisplaySettings: GalleryDisplaySettings(
            appTheme:
                AppTheme(focusColor: Colors.white, primaryColor: Colors.black),
            cropImage: true,
            showImagePreview: true,
          ),
        );
        if (details != null) await displayDetails(details);
      },
      child: const Text("Preview 3"),
    );
  }

  Future<void> displayDetails(SelectedImagesDetails details) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return DisplayImages(
              selectedBytes: details.selectedBytes,
              details: details,
              aspectRatio: details.aspectRatio);
        },
      ),
    );
  }
}

class DisplayImages extends StatefulWidget {
  final List<SelectedByte> selectedBytes;
  final double aspectRatio;
  final SelectedImagesDetails details;
  const DisplayImages({
    Key? key,
    required this.details,
    required this.selectedBytes,
    required this.aspectRatio,
  }) : super(key: key);

  @override
  State<DisplayImages> createState() => _DisplayImagesState();
}

class _DisplayImagesState extends State<DisplayImages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selected images/videos')),
      body: ListView.builder(
        itemBuilder: (context, index) {
          SelectedByte selectedByte = widget.selectedBytes[index];
          if (!selectedByte.isThatImage) {
            return _DisplayVideo(selectedByte: selectedByte);
          } else {
            return SizedBox(
                width: double.infinity,
                child: Image.file(selectedByte.selectedByte));
          }
        },
        itemCount: widget.selectedBytes.length,
      ),
    );
  }
}

class _DisplayVideo extends StatefulWidget {
  final SelectedByte selectedByte;
  const _DisplayVideo({Key? key, required this.selectedByte}) : super(key: key);

  @override
  State<_DisplayVideo> createState() => _DisplayVideoState();
}

class _DisplayVideoState extends State<_DisplayVideo> {
  late VideoPlayerController controller;
  late Future<void> initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.file(widget.selectedByte.selectedByte);
    initializeVideoPlayerFuture = controller.initialize();
    controller.setLooping(true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              )
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 1),
          );
        }
      },
    );
  }
}
