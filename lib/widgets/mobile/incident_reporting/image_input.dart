import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImageInput extends StatefulWidget {
  const ImageInput({super.key, required this.onPickMedia});

  final void Function(List<File> media) onPickMedia;

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  final List<File> _selectedMedia = [];
  final Map<File, VideoPlayerController> _videoControllers = {};

  Future<void> _takePicture() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera, maxWidth: 600);

    if (pickedImage == null) return;

    setState(() => _selectedMedia.add(File(pickedImage.path)));
    widget.onPickMedia(_selectedMedia);
  }

  Future<void> _recordVideo() async {
    final imagePicker = ImagePicker();
    final pickedVideo = await imagePicker.pickVideo(source: ImageSource.camera);

    if (pickedVideo == null) return;

    final videoFile = File(pickedVideo.path);
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();

    setState(() {
      _selectedMedia.add(videoFile);
      _videoControllers[videoFile] = controller;
    });

    widget.onPickMedia(_selectedMedia);
  }

  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null) {
      for (final path in result.paths) {
        final file = File(path!);
        if (file.path.endsWith(".mp4") || file.path.endsWith(".mov") || file.path.endsWith(".avi")) {
          final controller = VideoPlayerController.file(file);
          await controller.initialize();
          _videoControllers[file] = controller;
        }
        _selectedMedia.add(file);
      }
      setState(() {});
      widget.onPickMedia(_selectedMedia);
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: _selectedMedia.isEmpty
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text("No media selected", style: TextStyle(color: Colors.grey.shade600)),
            ],
          )
              : SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMedia.length,
              itemBuilder: (context, index) {
                final file = _selectedMedia[index];
                final isVideo = file.path.endsWith(".mp4") || file.path.endsWith(".mov") || file.path.endsWith(".avi");
                final videoController = _videoControllers[file];
                const desiredAspectRatio = 9/16; // You can adjust this value (e.g., 16/9, 4/3)

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: isVideo
                      ? videoController != null
                      ? AspectRatio(
                    aspectRatio: desiredAspectRatio, // Force the desired aspect ratio
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VideoPlayer(videoController),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator())
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isSmall = constraints.maxWidth < 500;
            final buttons = _buildButtons(isRowLayout: !isSmall);

            return isSmall
                ? Column(children: buttons)
                : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons);
          },
        ),
      ],
    );
  }

  List<Widget> _buildButtons({required bool isRowLayout}) {
    Widget wrap(Widget child) => isRowLayout ? Expanded(child: child) : child;

    return [
      wrap(ElevatedButton.icon(
        onPressed: _takePicture,
        icon: const Icon(Icons.camera, color: Color(0xFFFEC00F)),
        label: const Text("Take Photo", style: TextStyle(color: Color(0xFFFEC00F))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      )),
      const SizedBox(width: 8, height: 8),
      wrap(ElevatedButton.icon(
        onPressed: _recordVideo,
        icon: const Icon(Icons.videocam, color: Color(0xFFFEC00F)),
        label: const Text("Record Video", style: TextStyle(color: Color(0xFFFEC00F))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      )),
      const SizedBox(width: 8, height: 8),
      wrap(ElevatedButton.icon(
        onPressed: _pickMedia,
        icon: const Icon(Icons.photo_library, color: Color(0xFFFEC00F)),
        label: const Text("Select Files", style: TextStyle(color: Color(0xFFFEC00F))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      )),
    ];
  }
}