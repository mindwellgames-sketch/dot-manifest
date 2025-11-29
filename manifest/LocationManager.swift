import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let defaults = UserDefaults.standard

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?

    // Keys for UserDefaults
    private let latitudeKey = "cached_latitude"
    private let longitudeKey = "cached_longitude"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus

        // Only load cached location if user has granted permission
        // This prevents showing stale location data when permission is denied
        let hasPermission = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways

        if hasPermission {
            // Load cached location to prevent blue flash on app launch
            if let latitude = defaults.value(forKey: latitudeKey) as? Double,
               let longitude = defaults.value(forKey: longitudeKey) as? Double {
                lastLocation = CLLocation(latitude: latitude, longitude: longitude)
                #if DEBUG
                print("🌍 INIT: Loaded cached location: \(latitude), \(longitude)")
                #endif
            } else {
                #if DEBUG
                print("⚠️ INIT: No cached location found")
                #endif
            }
            // Request fresh location
            requestLocation()
        } else {
            #if DEBUG
            print("⚠️ INIT: Location permission not granted, skipping cache load")
            #endif
        }
    }

    // Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // Request a single location update
    func requestLocation() {
        locationManager.requestLocation()
    }

    // Get current location (cached or live)
    func getCurrentLocation() -> CLLocation? {
        return lastLocation
    }

    // Save location to UserDefaults for offline use
    private func cacheLocation(_ location: CLLocation) {
        defaults.set(location.coordinate.latitude, forKey: latitudeKey)
        defaults.set(location.coordinate.longitude, forKey: longitudeKey)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // If authorized, request location
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        lastLocation = location
        cacheLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location error: \(error.localizedDescription)")
        #endif
        // If live location fails, cached location will still be available
    }
}
