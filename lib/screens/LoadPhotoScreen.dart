import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter/utilities/constants.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:async';
import 'dart:ui' as ui;
import 'package:image/image.dart' as image;

import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/container.dart';

import 'package:flutter_painter/utilities/SignaturePainter.dart';

class LoadPhotoScreen extends StatefulWidget {
  _LoadPhotoScreenState createState() => _LoadPhotoScreenState();
}

class _LoadPhotoScreenState extends State<LoadPhotoScreen> {
  File? _imageFile;

  Offset offsetTap = Offset.zero;
  List<List<Offset>> allOffsets = List.empty(growable: true);
  List<Offset> lastOffsets = List.empty(growable: true);
  List<Offset> _points = <Offset>[];

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
          Center(
            child: Text(
              'Photo Editor',
              style: kButtonTextStyle,
            ),
          ),
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
                  _points = new List.from(_points)..add(localPosition);
                  allOffsets.last..add(localPosition);
                });
              },
              onPanEnd: (DragEndDetails details) {
                _points.clear();
              },
              child: new CustomPaint(
                  painter: new SignaturePainter(
                      background: _image,
                      allPoints: allOffsets,
                      points: _points)),
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
      setState(() {
        print('loaded image');
      });
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
    _points.clear();
    allOffsets.clear();
  }

  void save() async {
    isNeedSaveImage = true;
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    SignaturePainter painter =
        SignaturePainter(allPoints: allOffsets, points: _points);
    var size = context.size;
    painter.paint(canvas, size!);
    Future<ui.Image> savedImage = recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());

    Image img;
    File file;
    // String dir = (await getApplicationDocumentsDirectory()).path;

    // Directory appDir = await getApplicationDocumentsDirectory();
    // // Gets the part of path after the last separator.
    // //final fileName = appDir.basename(_imageFile?.path);
    // final savedImage1 = await _imageFile!.copy('${appDir.path}/fileName.jpg');

    String fullPath = '/abc.png'; //'''$dir/abc.png';
    savedImage.then((value) {
      file = File(fullPath);
      file.writeAsBytes(base64.decode(value.toString()));
    });

    print("saved ${savedImage.toString()}");
  }
}
