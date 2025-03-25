// Renders Firebase images and videos in a horizontal scroll view
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MediaViewer extends StatefulWidget {
  final List<Map<String, String>> mediaList;

  const MediaViewer({super.key, required this.mediaList});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  final PageController _controller = PageController();
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaList.isEmpty) {
      return const Center(child: Text("No media available."));
    }

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.mediaList.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final media = widget.mediaList[index];
              final type = media['type'];
              final url = media['url'];

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => FullscreenMediaViewer(media: media),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: type == 'image'
                        ? Image.network(url!, fit: BoxFit.cover)
                        : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill,
                              size: 40, color: Colors.black54),
                          SizedBox(height: 4),
                          Text("Video Preview",
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: widget.mediaList.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Colors.amber,
            dotColor: Colors.grey,
          ),
        ),
      ],
    );
  }
}


class FullscreenMediaViewer extends StatelessWidget {
  final Map<String, String> media;

  const FullscreenMediaViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final type = media['type'];
    final url = media['url'];

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: type == 'image'
                ? InteractiveViewer(
              child: Image.network(url!, fit: BoxFit.contain),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill,
                    size: 100, color: Colors.white70),
                const SizedBox(height: 12),
                const Text(
                  "Video playback coming soon...",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  url!,
                  style: const TextStyle(
                      color: Colors.white30, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          )
        ],
      ),
    );
  }
}




