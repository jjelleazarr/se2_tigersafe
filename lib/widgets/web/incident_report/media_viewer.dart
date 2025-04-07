import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/video_player.dart';

class MediaViewer extends StatefulWidget {
  final List<Map<String, String>> mediaList;

  const MediaViewer({super.key, required this.mediaList});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  final PageController _controller = PageController();
  int _activeIndex = 0;

  void _goTo(int index) {
    if (index >= 0 && index < widget.mediaList.length) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openFullscreen(Map<String, String> media) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: media['type'] == 'image'
                    ? Image.network(
                  media['url']!,
                  fit: BoxFit.contain,
                )
                    : AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(url: media['url']!),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.mediaList.length;

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (index) => setState(() => _activeIndex = index),
                itemBuilder: (context, index) {
                  final media = widget.mediaList[index];
                  final type = media['type'];
                  final url = media['url'];

                  return GestureDetector(
                    onTap: () => _openFullscreen(media),
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
                                  style:
                                  TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ⬅️ Left arrow
            if (total > 1)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 32),
                  onPressed: () => _goTo(_activeIndex - 1),
                ),
              ),

            // ➡️ Right arrow
            if (total > 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 32),
                  onPressed: () => _goTo(_activeIndex + 1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: total,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Colors.amber,
            dotColor: Colors.grey,
          ),
          onDotClicked: _goTo,
        ),
      ],
    );
  }
}