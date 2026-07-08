# flutter_asa

[![pub package](https://img.shields.io/pub/v/flutter_asa.svg)](https://pub.dev/packages/flutter_asa)

`flutter_asa` 是一个用于注册上报、Apple Search Ads 归因数据上传、订阅交易数据上传的 Flutter 插件/工具。

## 功能

- 注册用户和设备基础信息。
- 获取并上传 Apple Search Ads 归因 token 与归因详情。
- 上传订阅交易数据。
- 使用 AES-CBC 加密请求参数，并通过 `sct` 请求头传递服务端校验 token。
- 内置失败重试逻辑，适合在注册、归因、订阅上报链路中使用。

## 安装

插件已发布到 pub.dev：

https://pub.dev/packages/flutter_asa

推荐使用命令安装：

```bash
flutter pub add flutter_asa
```

也可以在 `pubspec.yaml` 中手动添加：

```yaml
dependencies:
  flutter_asa: ^1.0.3
```

本地开发调试时，可以使用 path 依赖：

```yaml
dependencies:
  flutter_asa:
    path: ../flutter_asa
```

然后执行：

```bash
flutter pub get
```

## 平台支持

| 平台 | 支持情况 |
| --- | --- |
| iOS | 支持 Apple Search Ads 归因 token 和归因详情获取。 |
| Android | 支持注册、订阅上报；ASA token 返回空字符串，归因详情返回空 Map。 |

## iOS 接入配置

插件已在 iOS Podspec 中弱链接 `AdServices.framework`。Apple Search Ads 归因能力要求 iOS 14.3 或更高版本；低于该版本时原生接口会返回不支持错误。

如果你的宿主工程没有自动链接系统库，可以在 Xcode 中打开 iOS 工程，选择 App Target，在 `General` -> `Frameworks, Libraries, and Embedded Content` 中手动添加 `AdServices.framework`，并将 `Embed` 设置为 `Do Not Embed`。

## 使用方法

### 1. 初始化配置

在业务启动后或用户登录后，先调用 `Asa.config`。后续注册、归因上传、订阅上传都会使用这些配置。

```dart
import 'package:flutter_asa/flutter_asa.dart';

void setupAsa() {
  Asa.config(
    aesSecretKey: '1234567890123456',
    aesIv: '1234567890123456',
    aesSctToken: 'your-sct-token',
    userId: 'user-id',
    appVersion: '1.0.3',
    deviceType: 'ios',
    deviceModel: 'iPhone',
    deviceOSVersion: '17.0',
  );
}
```

参数说明：

| 参数 | 说明 |
| --- | --- |
| `aesSecretKey` | AES 加密密钥 |
| `aesIv` | AES-CBC 初始化向量 |
| `aesSctToken` | 请求头 `sct` 的值 |
| `userId` | 当前用户 ID |
| `appVersion` | App 版本号 |
| `deviceType` | 设备类型，例如 `ios` 或 `android` |
| `deviceModel` | 设备型号 |
| `deviceOSVersion` | 系统版本 |

### 2. 注册上报

```dart
final success = await Asa.register(
  apiUrl: 'https://example.com/register',
  locale: 'zh-CN',
);

if (success) {
  // 注册上报成功
}
```

`register` 会上传用户、设备、IP 位置信息和 ASA 归因 token。成功后会在本地记录注册状态，避免重复注册上报。

如果你已经从其他链路拿到了归因详情，也可以通过 `attribution` 参数随注册接口一起上传：

```dart
await Asa.register(
  apiUrl: 'https://example.com/register',
  locale: 'zh-CN',
  attribution: {
    'iad-attribution': true,
    'iad-org-name': 'Example Org',
  },
);
```

### 3. 上传 ASA 归因数据

```dart
await Asa.uploadAttributionData(
  apiUrl: 'https://example.com/register',
  locale: 'zh-CN',
);
```

`uploadAttributionData` 会在 iOS 端通过插件内置原生桥接获取 Apple Search Ads 归因详情，并复用注册接口上传归因数据。Android 端返回空归因数据，因此该方法通常只需要在 iOS 归因链路中调用。

### 4. 上传订阅数据

```dart
final success = await Asa.uploadSubscriptionData(
  apiUrl: 'https://example.com/subscription',
  transactionId: 'origin-transaction-id',
  transactionDate: '1710000000000',
  locale: 'zh-CN',
  onSuccess: () {
    // 服务端确认成功后执行，例如标记本地交易已上报
  },
);

if (success) {
  // 订阅数据上传成功
}
```

`uploadSubscriptionData` 会上传用户、设备、IP 位置信息、ASA 归因 token、原始交易 ID 和原始购买时间。

## 服务端接口约定

插件会将业务参数 JSON 序列化后，使用 AES-CBC 加密，并以 Base64 字符串发送给服务端。

请求体：

```json
{
  "data": "encryptedBase64"
}
```

请求头：

```http
sct: your-sct-token
```

成功响应：

```json
{
  "code": 0
}
```

当服务端响应中的 `code == 0` 时，插件会认为请求成功。

### 注册与归因接口字段

`register` 和 `uploadAttributionData` 复用同一个服务端接口，主要字段如下：

| 字段 | 说明 |
| --- | --- |
| `userId` | 当前用户 ID |
| `fcmId` | 预留字段，当前为空字符串 |
| `appVersion` | App 版本号 |
| `deviceType` | 设备类型 |
| `devicePlatform` | 设备型号 |
| `deviceOSVersion` | 系统版本 |
| `locale` | 语言区域 |
| `timezone` | IP 定位返回的时区 |
| `ipCountry` | IP 定位返回的国家 |
| `ipState` | IP 定位返回的省/州 |
| `ipCity` | IP 定位返回的城市 |
| `attributionToken` | Apple Search Ads 归因 token，非 iOS 为空字符串 |
| `attribution` | Apple Search Ads 归因详情；无归因详情时为 `null` |

### 订阅接口字段

`uploadSubscriptionData` 会上传以下主要字段：

| 字段 | 说明 |
| --- | --- |
| `userId` | 当前用户 ID |
| `fcmId` | 预留字段，当前为空字符串 |
| `appVersion` | App 版本号 |
| `deviceType` | 设备类型 |
| `devicePlatform` | 设备型号 |
| `deviceOSVersion` | 系统版本 |
| `locale` | 语言区域 |
| `timezone` | IP 定位返回的时区 |
| `ipCountry` | IP 定位返回的国家 |
| `ipState` | IP 定位返回的省/州 |
| `ipCity` | IP 定位返回的城市 |
| `attributionToken` | Apple Search Ads 归因 token，非 iOS 为空字符串 |
| `originTransactionId` | 原始交易 ID |
| `originalPurchaseDateMs` | 原始购买时间戳 |

## 重试与本地状态

- `register`、`uploadAttributionData`、`uploadSubscriptionData` 最多都会尝试 10 次。
- 重试间隔会根据失败次数递增：前 3 次为 3 秒，第 4-6 次为 5 秒，之后为 10 秒。
- `register` 内部会串行执行注册尝试，避免多个注册/归因上报同时写入本地状态。
- `uploadSubscriptionData` 成功后会触发 `onSuccess`。
- 注册成功状态和归因数据上传成功状态会通过 `qs_storage_tool` 存储在本地。

## 注意事项

- 必须先调用 `Asa.config`，再调用注册、归因上传或订阅上传方法。
- `aesSecretKey` 和 `aesIv` 需要满足 AES 加密长度要求，例如 16、24 或 32 字节密钥，以及 16 字节 IV。
- `apiUrl` 由你的服务端提供，注册和归因上传可以使用同一个接口。
- 当前工具依赖 `ip_location`、`qs_storage_tool`、`net_dio_request`、`encrypt` 等包，iOS ASA 归因能力已内置到插件原生桥接中。
- 请确保服务端使用相同的 AES key、IV、CBC 模式和填充方式解密请求体。

## 示例

完整示例可以参考 `example/` 目录。

## 许可证

查看 [LICENSE](LICENSE)。
