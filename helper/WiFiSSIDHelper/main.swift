import AppKit
import CoreLocation
import CoreWLAN
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var finished = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    locationManager.delegate = self
    requestSSID()

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
      self?.finish(with: nil)
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    requestSSID()
  }

  private func requestSSID() {
    guard CLLocationManager.locationServicesEnabled() else {
      finish(with: nil)
      return
    }

    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      finish(with: CWWiFiClient.shared().interface()?.ssid())
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      finish(with: nil)
    @unknown default:
      finish(with: nil)
    }
  }

  private func finish(with ssid: String?) {
    guard !finished else { return }
    finished = true

    if let ssid, !ssid.isEmpty {
      FileHandle.standardOutput.write(Data((ssid + "\n").utf8))
    }

    fflush(stdout)
    NSApp.terminate(nil)
  }
}

@main
struct WiFiSSIDHelperApp {
  static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
  }
}
