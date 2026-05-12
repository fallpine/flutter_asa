import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_asa_attribution/flutter_asa_attribution.dart';
import 'package:ip_location/ip_location.dart';
import 'package:ip_location/ip_location_model.dart';
import 'package:net_dio_request/net_request.dart';
import 'package:qs_storage_tool/qs_storage_tool.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Asa {
  // 上传归因数据
  static const _kIsUploadAttributionDataKey = "isUploadAttributionDataKey";
  // 注册
  static const _kIsRegisterKey = "isRegisterKey";

  /// Func
  /// 配置
  static void config({
    required String aesSecretKey,
    required String aesIv,
    required String aesSctToken,
    required String userId,
    required String appVersion,
    required String deviceType,
    required String deviceModel,
    required String deviceOSVersion,
  }) {
    _aesSecretKey = aesSecretKey;
    _aesIv = aesIv;
    _aesSctToken = aesSctToken;
    _userId = userId;
    _appVersion = appVersion;
    _deviceType = deviceType;
    _deviceModel = deviceModel;
    _deviceOSVersion = deviceOSVersion;
  }

  /// 注册
  static Future<bool> register({
    required String apiUrl,
    required String locale,
    Map<String, dynamic>? attribution,
  }) async {
    var failureCount = 0;

    while (failureCount < 10) {
      final success = await _runRegisterAttemptLocked(
        apiUrl: apiUrl,
        locale: locale,
        attribution: attribution,
      );
      if (success) {
        return true;
      }

      failureCount += 1;
      if (failureCount < 10) {
        await Future.delayed(_retryDelay(failureCount));
      }
    }
    return false;
  }

  /// 注册内部方法
  static Future<bool> _runRegisterAttemptLocked({
    required String apiUrl,
    required String locale,
    Map<String, dynamic>? attribution,
  }) {
    final registerAttempt = _registerAttemptQueue.then(
      (_) =>
          _register(apiUrl: apiUrl, locale: locale, attribution: attribution),
    );
    _registerAttemptQueue = registerAttempt.then<void>((_) {}, onError: (_) {});
    return registerAttempt;
  }

  /// 注册内部方法
  static Future<bool> _register({
    required String apiUrl,
    required String locale,
    Map<String, dynamic>? attribution,
  }) async {
    // 是否已发送归因数据
    if (await QsStorageTool.getBool(key: _kIsUploadAttributionDataKey) ??
        false) {
      return true;
    }

    // 没归因数据，且已注册，直接返回
    if (attribution == null &&
        (await QsStorageTool.getBool(key: _kIsRegisterKey) ?? false)) {
      return true;
    }

    // 获取位置信息
    final loaction = await _getLocationByIp();
    // ASA归因token
    String attributionToken =
        await FlutterAsaAttribution.instance.attributionToken() ?? "";

    try {
      // 是否注册
      bool isRegister =
          await QsStorageTool.getBool(key: _kIsRegisterKey) ?? false;
      if (isRegister && attributionToken.isEmpty) {
        return false;
      }

      Map<String, dynamic> params = {
        "userId": _userId,
        "fcmId": "",
        "appVersion": _appVersion,
        "deviceType": _deviceType,
        "devicePlatform": _deviceModel,
        "deviceOSVersion": _deviceOSVersion,
        "locale": locale,
        "timezone": loaction?.timezone ?? "",
        "ipCountry": loaction?.country ?? "",
        "ipState": loaction?.regionName ?? "",
        "ipCity": loaction?.city ?? "",
        "attributionToken": attributionToken,
        "attribution": attribution,
      };

      String? encryptedParams = _encrypt(content: jsonEncode(params));
      if (encryptedParams == null) {
        _print("加密失败");
        return false;
      }

      var response = await NetRequest.shared.postJson(
        apiUrl,
        parameters: {"data": encryptedParams},
        headers: {"sct": _aesSctToken},
        isShowLoading: false,
      );

      if (response?["code"] == 0) {
        QsStorageTool.setBool(key: _kIsRegisterKey, value: true);
        if (attribution != null) {
          QsStorageTool.setBool(key: _kIsUploadAttributionDataKey, value: true);
          return true;
        }
      }
      return false;
    } catch (e) {
      _print("注册+归因失败 + $e");
      return false;
    }
  }

  /// 上传归因数据
  static Future<bool> uploadAttributionData({
    required String apiUrl,
    required String locale,
  }) async {
    var failureCount = 0;

    while (failureCount < 10) {
      final success = await _uploadAttributionData(
        apiUrl: apiUrl,
        locale: locale,
      );
      if (success) {
        return true;
      }

      failureCount += 1;
      if (failureCount < 10) {
        await Future.delayed(_retryDelay(failureCount));
      }
    }
    return false;
  }

  /// 上传归因数据内部方法
  static Future<bool> _uploadAttributionData({
    required String apiUrl,
    required String locale,
  }) async {
    // ASA归因数据
    await FlutterAsaAttribution.instance.attributionToken();
    try {
      Map<String, dynamic>? attribution = await FlutterAsaAttribution.instance
          .requestAttributionDetails();
      if (attribution == null) {
        return false;
      }

      var attributionMap = <String, dynamic>{};
      for (var entry in attribution.entries) {
        attributionMap[entry.key] = entry.value;
      }
      if (attributionMap.isEmpty) {
        return false;
      }
      return await register(
        apiUrl: apiUrl,
        locale: locale,
        attribution: attributionMap,
      );
    } catch (e) {
      _print("获取归因数据失败 + $e");
      return false;
    }
  }

  /// 上传订阅数据
  static Future<bool> uploadSubscriptionData({
    required String apiUrl,
    required String transactionId,
    required String transactionDate,
    required String locale,
    required VoidCallback onSuccess,
  }) async {
    var failureCount = 0;

    while (failureCount < 10) {
      final success = await _uploadSubscriptionData(
        apiUrl: apiUrl,
        transactionId: transactionId,
        transactionDate: transactionDate,
        locale: locale,
        onSuccess: onSuccess,
      );
      if (success) {
        return true;
      }

      failureCount += 1;
      if (failureCount < 10) {
        await Future.delayed(_retryDelay(failureCount));
      }
    }
    return false;
  }

  /// 上传订阅数据内部方法
  static Future<bool> _uploadSubscriptionData({
    required String apiUrl,
    required String transactionId,
    required String transactionDate,
    required String locale,
    required VoidCallback onSuccess,
  }) async {
    try {
      // 获取位置信息
      final loaction = await _getLocationByIp();
      // ASA归因token
      String attributionToken =
          await FlutterAsaAttribution.instance.attributionToken() ?? "";

      Map<String, dynamic> params = {
        "userId": _userId,
        "fcmId": "",
        "appVersion": _appVersion,
        "deviceType": _deviceType,
        "devicePlatform": _deviceModel,
        "deviceOSVersion": _deviceOSVersion,
        "locale": locale,
        "timezone": loaction?.timezone ?? "",
        "ipCountry": loaction?.country ?? "",
        "ipState": loaction?.regionName ?? "",
        "ipCity": loaction?.city ?? "",
        "attributionToken": attributionToken,
        "originTransactionId": transactionId,
        "originalPurchaseDateMs": transactionDate,
      };

      String? encryptedParams = _encrypt(content: jsonEncode(params));
      if (encryptedParams == null) {
        return false;
      }

      var response = await NetRequest.shared.postJson(
        apiUrl,
        parameters: {"data": encryptedParams},
        headers: {"sct": _aesSctToken},
        isShowLoading: false,
      );

      if (response?["code"] == 0) {
        onSuccess();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _print("上传订阅数据失败 + $e");
      return false;
    }
  }

  /// 根据 IP 获取省市区信息
  static Future<IpLocationModel?> _getLocationByIp() async {
    IpLocationModel? location = await IpLocation.getIpLocation();
    return location;
  }

  static Duration _retryDelay(int failureCount) {
    if (failureCount <= 3) {
      return const Duration(seconds: 3);
    }
    if (failureCount <= 6) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 10);
  }

  // 加密
  static String? _encrypt({required String content}) {
    if (_aesSecretKey == null || _aesIv == null) {
      return null;
    }

    try {
      final key = encrypt.Key.fromUtf8(_aesSecretKey!);
      final iv = encrypt.IV.fromUtf8(_aesIv!);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(content, iv: iv);

      return encrypted.base64;
    } catch (e) {
      _print("加密失败 + $e");
      return null;
    }
  }

  /// 打印
  static void _print(Object? object) {
    if (kDebugMode) {
      print("$object");
    }
  }

  /// Property
  // aes secret key
  static String? _aesSecretKey;
  // aes iv
  static String? _aesIv;
  // aes sct token
  static String? _aesSctToken;
  // 设备ID
  static String? _userId;
  // 版本号
  static String? _appVersion;
  // 设备类型
  static String? _deviceType;
  // 设备型号
  static String? _deviceModel;
  // 设备系统版本
  static String? _deviceOSVersion;
  // 注册尝试队列
  static Future<void> _registerAttemptQueue = Future.value();
}
