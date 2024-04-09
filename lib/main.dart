import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart'
    as img; // Importing image library for image processing

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  String outputPath = '';
  String inputPath = '';
  String inputBtn = '照片文件夹拖进来 或者点击选择文件夹';
  String outputBtn = '导出文件夹拖进来 或者点击选择文件夹';
  String resultBtn = '开始处理';
  bool _centerMode = false;
  var width = TextEditingController();
  var height = TextEditingController();
  List<String> failFiles = [];

  Offset? offset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('图片压缩+裁剪'),
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
                            inputPath = detail.files.first.path;
                            setState(() {
                              inputBtn = inputPath;
                            });
                          },
                          child: ElevatedButton(
                            onPressed: () async {
                              String? selectedDirectory =
                                  await FilePicker.platform.getDirectoryPath();

                              if (selectedDirectory != null) {
                                inputPath = selectedDirectory;
                                setState(() {
                                  inputBtn = inputPath;
                                });
                              }
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
                            setState(() {
                              outputBtn = outputPath;
                            });
                          },
                          child: ElevatedButton(
                            onPressed: () async {
                              String? selectedDirectory =
                                  await FilePicker.platform.getDirectoryPath();

                              if (selectedDirectory != null) {
                                outputPath = selectedDirectory;
                                setState(() {
                                  outputBtn = outputPath;
                                });
                              }
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
                      child: Row(
                        children: [
                          Checkbox(
                            value: _centerMode,
                            onChanged: (value) {
                              setState(() {
                                _centerMode = value!;
                              });
                            },
                          ),
                          const Text('居中裁剪')
                        ],
                      ),
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
              SizedBox(
                height: 200,
                child: ListView.builder(
                    itemCount: failFiles.length,
                    itemBuilder: (BuildContext con, int index) {
                      return SelectableText('${failFiles[index]}');
                    }),
              )
            ],
          ),
        ));
  }

  processImages() async {
    if (!isNumeric(width.text) || !isNumeric(height.text)) {
      setState(() {
        resultBtn = '图片宽高需要为数字';
      });
      return;
    }

    setState(() {
      failFiles.clear();
    });
    bool isDirectory = await Directory(inputPath).exists();
    if (isDirectory) {
      for (final entity in Directory(inputPath).listSync()) {
        if (entity is File) {
          await processFile(XFile(entity.path), int.parse(width.text),
              int.parse(height.text));
        }
      }
    }
    setState(() {
      outputPath = '';
      inputPath = '';
      resultBtn = '处理结束';
      _centerMode = false;
      inputBtn = '照片文件夹拖进来 或者点击选择文件夹';
      outputBtn = '导出文件夹拖进来 或者点击选择文件夹';

      width.text = "";
      height.text = "";
    });
  }

  Future<void> processFile(
      XFile entity, int targetWidth, int targetHeight) async {
    final fileName = entity.path.split('/').last;
    try {
      if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.bmp')) {
        try {
          var image = img.decodeImage(await entity.readAsBytes());
          // Convert to RGB if not already
          if (image!.numChannels != 3) {
            image = img.grayscale(image);
          }

          final targetRatio = targetWidth / targetHeight;

          final width = image.width;
          final height = image.height;
          final aspectRatio = width / height;
          if (aspectRatio < targetRatio) {
            var newHeight = (targetWidth / aspectRatio).round();
            image =
                img.copyResize(image, width: targetWidth, height: newHeight);
            var y = (newHeight - targetHeight) / 2;

            if (!_centerMode) {
              image = img.copyCrop(image,
                  x: 0, y: 0, width: targetWidth, height: targetHeight);
            } else {
              image = img.copyCrop(image,
                  x: 0, y: y.toInt(), width: targetWidth, height: targetHeight);
            }
          } else {
            var newWidth = (targetHeight * aspectRatio).round();
            image =
                img.copyResize(image, width: newWidth, height: targetHeight);

            var left = (newWidth - targetWidth) / 2;

            // var right = (newWidth + targetWidth) / 2;
            image = img.copyCrop(image,
                x: left.toInt(),
                y: 0,
                width: targetWidth,
                height: targetHeight);
          }

          await File('$outputPath/$fileName')
              .writeAsBytes(img.encodeJpg(image));
          setState(() {
            failFiles.add('成功 $fileName');
          });
        } catch (e) {
          setState(() {
            failFiles.add('失败 $fileName');
          });
        }
      } else {
        setState(() {
          failFiles.add('失败 $fileName');
        });
      }
    } catch (e) {
      setState(() {
        failFiles.add('失败 $fileName');
      });
    }
  }

  bool isNumeric(String? str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }
}
