//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_asa/FlutterAsaPlugin.h>)
#import <flutter_asa/FlutterAsaPlugin.h>
#else
@import flutter_asa;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<ip_location/IpLocationPlugin.h>)
#import <ip_location/IpLocationPlugin.h>
#else
@import ip_location;
#endif

#if __has_include(<net_dio_request/NetDioRequestPlugin.h>)
#import <net_dio_request/NetDioRequestPlugin.h>
#else
@import net_dio_request;
#endif

#if __has_include(<qs_storage_tool/QsStorageToolPlugin.h>)
#import <qs_storage_tool/QsStorageToolPlugin.h>
#else
@import qs_storage_tool;
#endif

#if __has_include(<qs_toast/QsToastPlugin.h>)
#import <qs_toast/QsToastPlugin.h>
#else
@import qs_toast;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterAsaPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterAsaPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [IpLocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"IpLocationPlugin"]];
  [NetDioRequestPlugin registerWithRegistrar:[registry registrarForPlugin:@"NetDioRequestPlugin"]];
  [QsStorageToolPlugin registerWithRegistrar:[registry registrarForPlugin:@"QsStorageToolPlugin"]];
  [QsToastPlugin registerWithRegistrar:[registry registrarForPlugin:@"QsToastPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
