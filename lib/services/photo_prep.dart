import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// 인형 화면에 띄울 사진을 고르고, 5:3 으로 자르고, 줄인다.
///
/// 원본(최대 수 MB)을 그대로 올리면 인형이 미국 S3 에서 받느라 사진이 1~5초
/// 늦게 뜬다. 인형 화면(800×480)의 두 배인 긴 변 1600px, JPEG 80 으로 줄이면
/// 보통 150~300KB 다. 서버도 한 번 더 줄이지만 올리는 시간도 아끼려고 여기서 줄인다.
///
/// 가족 메시지 사진과 추억 사진이 같이 쓴다.
class PreparedPhoto {
  const PreparedPhoto({required this.bytes, this.original});

  /// 인형 화면에 띄울 사진. 5:3 으로 잘렸거나, 전체 보기를 골랐으면 줄이기만 했다.
  final Uint8List bytes;

  /// 자르기 전 사진(줄이기만 함). 잘랐을 때만 있다.
  ///
  /// 인형은 추억 사진의 내용을 읽어 기억 문장을 만든다. 잘린 부분이 기억에서
  /// 빠지지 않게 서버에 함께 올린다.
  final Uint8List? original;

  /// 올릴 때 쓰는 파일 이름. 서버는 확장자로 이미지인지 가린다.
  String get filename => 'photo.jpg';
}

const _maxSide = 1600;
const _quality = 80;

/// 갤러리에서 사진을 고르고 인형 화면에 맞게 다듬는다. 도중에 그만두면 null.
Future<PreparedPhoto?> pickPhotoForDoll(BuildContext context) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return null;
  final pickedBytes = await picked.readAsBytes();

  // 웹은 자르기 화면을 따로 꾸며야 해서 줄이지 않고 그대로 보낸다. 서버가 줄인다.
  if (kIsWeb) return PreparedPhoto(bytes: pickedBytes);
  if (!context.mounted) return null;

  final crop = await _askCrop(context);
  if (crop == null) return null;

  final original = await shrinkPhoto(pickedBytes);
  if (!crop) return PreparedPhoto(bytes: original);

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: const CropAspectRatio(ratioX: 5, ratioY: 3),
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: _quality,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: '인형 화면에 맞게 자르기',
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: '인형 화면에 맞게 자르기',
        doneButtonTitle: '완료',
        cancelButtonTitle: '취소',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null;
  return PreparedPhoto(
    bytes: await shrinkPhoto(await cropped.readAsBytes()),
    original: original,
  );
}

/// 긴 변 1600px 이하, JPEG 80 으로 줄인다. EXIF 회전은 실제 회전으로 반영한다.
///
/// flutter_image_compress 는 min(가로/minWidth, 세로/minHeight) 로 줄인다.
/// 회전 정보에 따라 가로·세로가 뒤바뀌어 보일 수 있어서, 두 값을 똑같이
/// '짧은 변을 얼마로 줄일지' 로 넘긴다. 그러면 방향과 상관없이 긴 변이 1600 이 된다.
Future<Uint8List> shrinkPhoto(Uint8List bytes) async {
  final size = await _imageSize(bytes);
  final longSide = math.max(size.width, size.height);
  final shortSide = math.min(size.width, size.height);
  final target = longSide > _maxSide
      ? (shortSide * _maxSide / longSide).round()
      : shortSide;
  return FlutterImageCompress.compressWithList(
    bytes,
    minWidth: target,
    minHeight: target,
    quality: _quality,
    format: CompressFormat.jpeg,
  );
}

/// 사진을 다 풀지 않고 크기만 읽는다.
Future<({int width, int height})> _imageSize(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final size = (width: descriptor.width, height: descriptor.height);
  descriptor.dispose();
  buffer.dispose();
  return size;
}

/// 자를지 물어본다. true 면 5:3 으로 자르기, false 면 전체 보기, null 이면 취소.
Future<bool?> _askCrop(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '인형 화면에 어떻게 보여드릴까요?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.crop),
              title: const Text('화면에 꽉 차게 자르기'),
              subtitle: const Text('인형 화면 비율(5:3)에 맞게 잘라요'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.fit_screen_outlined),
              title: const Text('자르지 않고 전체 보기'),
              subtitle: const Text('단체 사진처럼 다 보여야 할 때. 화면 가장자리가 비어 보여요'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    ),
  );
}
