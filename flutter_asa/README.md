# flutter_asa

[![pub package](https://img.shields.io/pub/v/flutter_asa.svg)](https://pub.dev/packages/flutter_asa)

`flutter_asa` 是一个用于注册上报、Apple Search Ads 归因数据上传、订阅交易数据上传的 Flutter 插件/工具。

`flutter_asa` is a Flutter plugin/helper for registration reporting, Apple Search Ads attribution upload, and subscription transaction upload.

## 功能 / Features

- 注册用户和设备基础信息。
- 获取并上传 Apple Search Ads 归因 token 与归因详情。
- 上传订阅交易数据。
- 使用 AES-CBC 加密请求参数，并通过 `sct` 请求头传递服务端校验 token。
- 内置失败重试逻辑，适合在注册、归因、订阅上报链路中使用。

## 安装 / Installation

插件已发布到 pub.dev：

The package is available on pub.dev:

https://pub.dev/packages/flutter_asa

推荐使用命令安装：

Install with:

```bash
flutter pub add flutter_asa
```

也可以在 `pubspec.yaml` 中手动添加：

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_asa: ^1.0.2
```

本地开发调试时，可以使用 path 依赖：

For local development, use a path dependency:

```yaml
dependencies:
  flutter_asa:
    path: ../flutter_asa
```

然后执行：

Then run:

```bash
flutter pub get
```

## iOS 接入配置 / iOS Setup

在 Xcode 中打开 iOS 工程，选择 App Target，在 `General` -> `Frameworks, Libraries, and Embedded Content` 中添加以下系统库，并将 `Embed` 设置为 `Do Not Embed`：

Open the iOS project in Xcode, select the App Target, then add the following system frameworks under `General` -> `Frameworks, Libraries, and Embedded Content`. Set `Embed` to `Do Not Embed` for each one:

| Framework | Embed |
| --- | --- |
| `AdServices.framework` | `Do Not Embed` |
| `AdSupport.framework` | `Do Not Embed` |
| `iAd.framework` | `Do Not Embed` |

## 使用方法 / Usage

### 1. 初始化配置 / Configure

在业务启动后或用户登录后，先调用 `Asa.config`。后续注册、归因上传、订阅上传都会使用这些配置。

Call `Asa.config` after app startup or user login. Registration, attribution upload, and subscription upload all depend on this configuration.

```dart
import 'package:flutter_asa/flutter_asa.dart';

void setupAsa() {
  Asa.config(
    aesSecretKey: '1234567890123456',
    aesIv: '1234567890123456',
    aesSctToken: 'your-sct-token',
    userId: 'user-id',
    appVersion: '1.0.2',
    deviceType: 'ios',
    deviceModel: 'iPhone',
    deviceOSVersion: '17.0',
  );
}
```

参数说明 / Parameters:

| 参数 | 说明 | Description |
| --- | --- | --- |
| `aesSecretKey` | AES 加密密钥 | AES secret key |
| `aesIv` | AES-CBC 初始化向量 | AES-CBC initialization vector |
| `aesSctToken` | 请求头 `sct` 的值 | Value for the `sct` request header |
| `userId` | 当前用户 ID | Current user ID |
| `appVersion` | App 版本号 | App version |
| `deviceType` | 设备类型，例如 `ios` 或 `android` | Device type, such as `ios` or `android` |
| `deviceModel` | 设备型号 | Device model |
| `deviceOSVersion` | 系统版本 | OS version |

### 2. 注册上报 / Register

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

`register` uploads user info, device info, IP location info, and the ASA attribution token. After a successful request, the registration state is stored locally to avoid duplicate registration reports.

### 3. 上传 ASA 归因数据 / Upload ASA Attribution Data

```dart
await Asa.uploadAttributionData(
  apiUrl: 'https://example.com/register',
  locale: 'zh-CN',
);
```

`uploadAttributionData` 会在 iOS 端通过插件内置原生桥接获取 Apple Search Ads 归因详情，并复用注册接口上传归因数据。Android 端暂返回空归因数据。

`uploadAttributionData` gets Apple Search Ads attribution details through the built-in native bridge on iOS and uploads them through the registration API. Android currently returns empty attribution data.

### 4. 上传订阅数据 / Upload Subscription Data

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

`uploadSubscriptionData` uploads user info, device info, IP location info, the ASA attribution token, original transaction ID, and original purchase time.

## 服务端接口约定 / Server API Contract

插件会将业务参数 JSON 序列化后，使用 AES-CBC 加密，并以 Base64 字符串发送给服务端。

The plugin serializes request parameters as JSON, encrypts them with AES-CBC, and sends the encrypted Base64 string to the server.

请求体 / Request body:

```json
{
  "data": "encryptedBase64"
}
```

请求头 / Request headers:

```http
sct: your-sct-token
```

成功响应 / Successful response:

```json
{
  "code": 0
}
```

当服务端响应中的 `code == 0` 时，插件会认为请求成功。

The request is treated as successful when the server response contains `code == 0`.

## 重试与本地状态 / Retry and Local State

- `register` 失败后会持续重试，重试间隔依次为 3 秒、5 秒、10 秒。
- `uploadSubscriptionData` 失败后会持续重试，成功后触发 `onSuccess`。
- `uploadAttributionData` 最多重试 10 次。
- 注册成功状态和归因数据上传成功状态会通过 `qs_storage_tool` 存储在本地。

## 注意事项 / Notes

- 必须先调用 `Asa.config`，再调用注册、归因上传或订阅上传方法。
- `aesSecretKey` 和 `aesIv` 需要满足 AES 加密长度要求，例如 16、24 或 32 字节密钥，以及 16 字节 IV。
- `apiUrl` 由你的服务端提供，注册和归因上传可以使用同一个接口。
- 当前工具依赖 `ip_location`、`qs_storage_tool`、`net_dio_request`、`encrypt` 等包，iOS ASA 归因能力已内置到插件原生桥接中。
- 请确保服务端使用相同的 AES key、IV、CBC 模式和填充方式解密请求体。

## Example

完整示例可以参考 `example/` 目录。

See the `example/` directory for a runnable Flutter example.

## License

See [LICENSE](LICENSE).
