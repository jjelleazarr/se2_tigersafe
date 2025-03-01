import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImageInput extends StatefulWidget {
  const ImageInput({super.key, required this.onPickMedia});

  final void Function(List<File> media) onPickMedia;

  @override
  State<ImageInput> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  List<File> _selectedMedia = [];

  // 📌 Capture Photo from Camera
  Future<void> _takePicture() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.camera, maxWidth: 600);

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedMedia.add(File(pickedImage.path));
    });

    widget.onPickMedia(_selectedMedia);
  }

  // 📌 Record Video from Camera
  Future<void> _recordVideo() async {
    final imagePicker = ImagePicker();
    final pickedVideo =
        await imagePicker.pickVideo(source: ImageSource.camera);

    if (pickedVideo == null) {
      return;
    }

    setState(() {
      _selectedMedia.add(File(pickedVideo.path));
    });

    widget.onPickMedia(_selectedMedia);
  }

  // 📌 Select Multiple Images/Videos from Gallery
  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media, // Allows both images & videos
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedMedia.addAll(result.paths.map((path) => File(path!)));
      });

      widget.onPickMedia(_selectedMedia);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: _selectedMedia.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 50, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      "No media selected",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                )
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedMedia.length,
                    itemBuilder: (context, index) {
                      File file = _selectedMedia[index];
                      bool isVideo = file.path.endsWith(".mp4") ||
                          file.path.endsWith(".mov") ||
                          file.path.endsWith(".avi");

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: isVideo
                            ? Column(
                                children: [
                                  const Icon(Icons.videocam, size: 80),
                                  Text(file.path.split('/').last,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  file,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      );
                    },
                  ),
                ),
        ),  const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _takePicture,
              icon: const Icon(Icons.camera),
              label: const Text("Take Photo"),
            ),
            ElevatedButton.icon(
              onPressed: _recordVideo,
              icon: const Icon(Icons.videocam),
              label: const Text("Record Video"),
            ),
            ElevatedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select Files"),
            ),
          ],
        ),
      ],
    );
  }
}
