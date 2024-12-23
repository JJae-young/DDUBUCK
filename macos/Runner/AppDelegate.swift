import Cocoa
import FlutterMacOS
import GoogleMaps // Google Maps SDK 추가

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func application(
    _ application: NSApplication,
    didFinishLaunchingWithOptions launchOptions: [NSApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Google Maps API Key 설정
    GMSServices.provideAPIKey("AIzaSyAM2HDUq5-t5UNzFtx0gFTzZO4tsxIfcuY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
