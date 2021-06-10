import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_painter/utilities/constants.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_painter/utilities/CanvasPainter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LoadPhotoScreen extends StatefulWidget {
  _LoadPhotoScreenState createState() => _LoadPhotoScreenState();
}

class _LoadPhotoScreenState extends State<LoadPhotoScreen> {
  File? _imageFile;
  Offset offsetTap = Offset.zero;
  List<List<Offset>> allOffsets = List.empty(growable: true);
  List<Offset> lastOffsets = List.empty(growable: true);

  ui.Image? _image;

  bool isNeedSaveImage = false;
  bool isCanRedo = false;

  /// Get from gallery
  _getFromGallery() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onPanStart: (DragStartDetails details) {
                setState(() {
                  allOffsets.add(List.empty(growable: true));
                });
              },
              onPanUpdate: (DragUpdateDetails details) {
                setState(() {
                  RenderBox referenceBox =
                      context.findRenderObject() as RenderBox;
                  Offset localPosition =
                      referenceBox.globalToLocal(details.globalPosition);
                  allOffsets.last..add(localPosition);
                });
              },
              onPanEnd: (DragEndDetails details) {},
              child: new CustomPaint(
                  painter: new CanvasPainter(
                      background: _image, allPoints: allOffsets)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              ElevatedButton(onPressed: load, child: Text('load')),
              ElevatedButton(onPressed: undo, child: Text('undo')),
              ElevatedButton(onPressed: redo, child: Text('redo')),
              ElevatedButton(onPressed: clear, child: Text('clear')),
              ElevatedButton(onPressed: save, child: Text('save')),
            ],
          ),
        ],
      ),
    );
  }

  void load() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      final ui.Image image = await loadImage(_imageFile!.readAsBytesSync());
      _image = image;
      setState(() {});
    }
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> imageCompleter = new Completer();
    ui.decodeImageFromList(Uint8List.fromList(img), (ui.Image img) {
      imageCompleter.complete(img);
    });
    return imageCompleter.future;
  }

  void undo() {
    if (allOffsets.length > 0) {
      lastOffsets = allOffsets.last;
      allOffsets.removeLast();
      isCanRedo = true;
    }
  }

  void redo() {
    if (isCanRedo) {
      allOffsets.add(lastOffsets);
      isCanRedo = false;
    }
  }

  void clear() {
    allOffsets.clear();
  }

  Future<ui.Image> get rendered {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    CanvasPainter painter =
        CanvasPainter(background: _image, allPoints: allOffsets);
    var size = context.size;
    painter.paint(canvas, size!);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  void save() async {
    isNeedSaveImage = true;

    ui.Image renderedImage = await rendered;
    var image;
    setState(() {
      image = renderedImage;
    });

    var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    saveFile(pngBytes, 'painter_${DateTime.now()}.png');
  }

  Future<bool> saveFile(var bytes, String fileName) async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = (await getExternalStorageDirectory())!;
          String newPath = "";
          print(directory);
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/PainterApp";
          directory = Directory(newPath);
        } else {
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File(directory.path + "/$fileName");
        saveFile.writeAsBytes(bytes.buffer.asInt8List());
        print('save to ${directory.path + "/$fileName"}');
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<String> get _externalPath async {
    final directory = await getExternalStorageDirectory();

    return directory!.path;
  }
}
