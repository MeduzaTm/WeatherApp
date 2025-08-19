import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var geocodeContinuation: CheckedContinuation<String, Error>?
    private var authContinuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // Возвращает человекочитаемое название города, если доступно.
    // Если реверс-геокод не даст город — вернет строку "lat,lon".
    func getCurrentCity() async throws -> String {
        try await requestAuthorizationIfNeeded()
        let location = try await requestLocationOnce()
        return try await reverseGeocode(location: location)
    }

    // Возвращает координаты как строку "lat,lon" (рекомендуется для запроса WeatherAPI)
    func getCurrentCoordinatesQuery() async throws -> String {
        try await requestAuthorizationIfNeeded()
        let location = try await requestLocationOnce()
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }

    // MARK: - Authorization
    private func requestAuthorizationIfNeeded() async throws {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return
        case .notDetermined:
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self.authContinuation = continuation
                self.locationManager.requestWhenInUseAuthorization()
            }
        default:
            throw NSError(domain: "LocationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет доступа к геолокации. Разрешите доступ в настройках."])
        }
    }

    // MARK: - Single-shot location
    private func requestLocationOnce() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    // MARK: - Reverse geocoding
    private func reverseGeocode(location: CLLocation) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.geocodeContinuation = continuation
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let _ = error {
                    continuation.resume(returning: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
                    return
                }
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.administrativeArea ?? "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                    continuation.resume(returning: city)
                } else {
                    continuation.resume(returning: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthChange(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthChange(status)
    }

    private func handleAuthChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            authContinuation?.resume()
            authContinuation = nil
        case .denied, .restricted:
            authContinuation?.resume(throwing: NSError(domain: "LocationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Доступ к геолокации запрещен пользователем."]))
            authContinuation = nil
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
