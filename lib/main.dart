import 'dart:io';
import 'dart:ui' as ui;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart'
    as img; // Importing image library for image processing
import 'package:cross_file/cross_file.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Image Processing',
      home: ExampleDragTarget(),
    );
  }
}

class ExampleDragTarget extends StatefulWidget {
  const ExampleDragTarget({Key? key}) : super(key: key);

  @override
  ExampleDragTargetState createState() => ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  List<XFile> _list = [];
  String outputPath = "/Users/mt/MT/宝/图片处理/导出";
  String inputBtn = '照片文件夹拖进来';
  String outputBtn = '导出文件夹拖进来';
  String resultBtn = '开始处理';
  bool _dragging = false;
  var width = TextEditingController();
  var height = TextEditingController();

  Offset? offset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Processing'),
        ),
        body: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropTarget(
                          onDragDone: (detail) {
                            // 处理拖拽完成事件
                            _list = detail.files;
                            setState(() {
                              inputBtn = _list.first.path;
                            });
                          },
                          child: ElevatedButton(
                            onPressed: () {
                              // 按钮1的点击事件
                            },
                            child: Text(inputBtn),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropTarget(
                          onDragDone: (detail) {
                            outputPath = detail.files.first.path;
                            print('${outputPath}');
                            setState(() {
                              outputBtn = outputPath;
                            });
                          },
                          child: ElevatedButton(
                            onPressed: () {
                              // 按钮2的点击事件
                              print('按钮2被点击了');
                            },
                            child: Text(outputBtn),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 100,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: width,
                      decoration: const InputDecoration(
                        labelText: '宽度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Container(
                    width: 200,
                    height: 100,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: height,
                      decoration: const InputDecoration(
                        labelText: '高度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // 按钮2的点击事件
                          setState(() {
                            resultBtn = '处理中...';
                          });
                          processImages();
                        },
                        child: Text(resultBtn),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  processImages() async {
    // final inputFolder = Directory('/Users/mt/MT/宝/图片处理/导演');
    // final outputFolder = Directory('/Users/mt/MT/宝/图片处理/导出');

    // if (!outputFolder.existsSync()) {
    //   outputFolder.createSync(recursive: true);
    // }

    for (final entity in _list) {
      bool isDirectory = await Directory(entity.path).exists();
      if (isDirectory) {
        print('${entity.name} ${entity.path}');

        for (final entity in Directory(entity.path).listSync()) {
          if (entity is File) {
            print('${entity.path}');
            await processFile(XFile(entity.path), int.parse(width.text), int.parse(height.text));
          }
        }

/*        await Directory(entity.path).list().forEach((element) async {
          print('${element.path}');
          await processFile(XFile(element.path));
        });*/
        print("MTMTMT");

      }
    }
    setState(() {
      print("MTMTMT");
      resultBtn = '处理结束';

      inputBtn = '照片文件夹拖进来';
      outputBtn = '导出文件夹拖进来';

      width.text = "";
      height.text = "";
    });
  }

  Future<void> processFile(XFile entity, int targetWidth, int targetHeight) async {
    final fileName = entity.path.split('/').last;
    if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.bmp')) {
      // Read image
      var image = img.decodeImage(await entity.readAsBytes());

      // Convert to RGB if not already
      if (image!.numChannels != 3) {
        image = img.grayscale(image);
      }

      // Define target width and height
      // final targetWidth = 200;
      // final targetHeight = 240;
      final targetRatio = targetWidth / targetHeight;

      final width = image.width;
      final height = image.height;
      final aspectRatio = width / height;
      if (aspectRatio < targetRatio) {
        var newHeight = (targetWidth / aspectRatio).round();
        image = img.copyResize(image, width: targetWidth, height: newHeight);
        image = img.copyCrop(image, x: 0, y: 0, width: targetWidth, height: targetHeight);
      } else {
        var newWidth = (targetHeight * aspectRatio).round();
        image = img.copyResize(image, width: newWidth, height: targetHeight);

        var left = (newWidth - targetWidth) / 2;

        // var right = (newWidth + targetWidth) / 2;
        image = img.copyCrop(image, x: left.toInt(), y: 0, width: targetWidth, height: targetHeight);
      }

      // Save processed image
      await File('$outputPath/$fileName').writeAsBytes(img.encodeJpg(image));

      print("processed $fileName");
    }
  }
}
