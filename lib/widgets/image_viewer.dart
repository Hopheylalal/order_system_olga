import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatelessWidget {

  final url;

  const ImageViewer({Key key, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Фото'),
      ),
      body: Container(
        child: PhotoView(
          imageProvider: NetworkImage(url),
          loadingBuilder: (context, progress) => Center(
            child: Container(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                value: progress == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
