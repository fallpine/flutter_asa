import AdServices
import Flutter
import UIKit

public class FlutterAsaPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_asa", binaryMessenger: registrar.messenger())
    let instance = FlutterAsaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "attributionToken":
      result(attributionTokenResult())
    case "requestAttributionDetails":
      requestAttributionDetails(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func attributionTokenResult() -> Any {
    do {
      return try attributionToken()
    } catch {
      return FlutterError(
        code: "ATTRIBUTION_TOKEN_FAILED",
        message: error.localizedDescription,
        details: nil
      )
    }
  }

  private func attributionToken() throws -> String {
    guard #available(iOS 14.3, *) else {
      throw FlutterAsaError.unsupportedIOSVersion
    }
    return try AAAttribution.attributionToken()
  }

  private func requestAttributionDetails(result: @escaping FlutterResult) {
    let token: String
    do {
      token = try attributionToken()
    } catch {
      result(
        FlutterError(
          code: "ATTRIBUTION_TOKEN_FAILED",
          message: error.localizedDescription,
          details: nil
        )
      )
      return
    }

    guard !token.isEmpty else {
      result(
        FlutterError(
          code: "ATTRIBUTION_TOKEN_EMPTY",
          message: "Failed to retrieve attribution token",
          details: nil
        )
      )
      return
    }

    guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
      result(
        FlutterError(
          code: "INVALID_URL",
          message: "Invalid Apple AdServices attribution URL",
          details: nil
        )
      )
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
    request.httpBody = token.data(using: .utf8)

    URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "ATTRIBUTION_REQUEST_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
        return
      }

      guard let data = data else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "ATTRIBUTION_RESPONSE_EMPTY",
              message: "Apple AdServices attribution response is empty",
              details: nil
            )
          )
        }
        return
      }

      do {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        let attribution = json as? [String: Any] ?? [:]
        DispatchQueue.main.async {
          result(attribution)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "ATTRIBUTION_RESPONSE_INVALID",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }.resume()
  }
}

private enum FlutterAsaError: LocalizedError {
  case unsupportedIOSVersion

  var errorDescription: String? {
    switch self {
    case .unsupportedIOSVersion:
      return "Apple Search Ads attribution requires iOS 14.3 or later"
    }
  }
}
