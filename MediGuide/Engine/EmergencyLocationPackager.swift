import Foundation
import CoreLocation

@MainActor
final class EmergencyLocationPackager: NSObject {

    private var locationManager: CLLocationManager?
    private var continuation: CheckedContinuation<String, Never>?

    func captureLocationURL() async -> String {
        await withCheckedContinuation { cont in
            self.continuation = cont
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager = manager
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                cont.resume(returning: "")
                self.continuation = nil
            }
        }
    }

    private func finish(_ url: String) {
        locationManager = nil
        continuation?.resume(returning: url)
        continuation = nil
    }
}

extension EmergencyLocationPackager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        let url = "https://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)"
        Task { @MainActor in self.finish(url) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish("") }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            Task { @MainActor in self.finish("") }
        }
    }
}
