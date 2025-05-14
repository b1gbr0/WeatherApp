import CoreLocation
import Combine

final class WeatherViewModel: NSObject, ObservableObject {
    @Published var location: WeatherLocation?
    @Published var currentWeather: CurrentWeather?
    @Published var hourlyForecast: [HourlyWeather]?
    @Published var dailyForecast: [ForecastDay]?

    @Published var error: Error?
    @Published var isLoading: Bool = false

    private let service: WeatherServiceProtocol
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var hasRequestedLocation = false
    private let defaultCity = Bundle.main.defaultCity

    init(service: WeatherServiceProtocol) {
        self.service = service
        super.init()
        locationManager.delegate = self
    }

    func loadData() {
        if !hasRequestedLocation && locationManager.authorizationStatus == .notDetermined {
            hasRequestedLocation = true
            locationManager.requestWhenInUseAuthorization()
            return
        }
        isLoading = true

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted, .notDetermined:
            loadForecast(for: defaultCity)
        @unknown default:
            loadForecast(for: defaultCity)
        }
    }

    private func loadForecast(for query: String) {
        service.fetchForecast(for: query)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                isLoading = false
                if case let .failure(err) = completion {
                    error = err
                } else {
                    error = nil
                }
            }, receiveValue: { [weak self] response in
                guard let self else { return }
                location = response.location
                currentWeather = response.current
                let now = Date().timeIntervalSince1970
                let theRestOfToday = response.forecast.forecastday.first?.hour.filter { $0.timeEpoch > now } ?? []
                let theNextDay = response.forecast.forecastday.count > 1 ? response.forecast.forecastday[1].hour : []
                hourlyForecast = theRestOfToday + theNextDay
                dailyForecast = response.forecast.forecastday
            })
            .store(in: &cancellables)
    }
}

extension WeatherViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else if status == .denied || status == .restricted {
            loadForecast(for: defaultCity)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            loadForecast(for: defaultCity)
            return
        }

        let query = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        loadForecast(for: query)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        loadForecast(for: defaultCity)
    }
}

private extension Bundle {
    var defaultCity: String {
        guard let key = object(forInfoDictionaryKey: "DefaultCity") as? String else {
            fatalError("⚠️ DefaultCity not found in Info.plist")
        }
        return key
    }
}
