import Foundation
import Combine

protocol WeatherServiceProtocol {
    func fetchForecast(for query: String) -> AnyPublisher<ForecastWeatherResponse, Error>
}

final class WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchForecast(for query: String) -> AnyPublisher<ForecastWeatherResponse, Error> {
        guard var components = URLComponents(string: "https://api.weatherapi.com/v1/forecast.json") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "days", value: "7"), // Free plan is limited only by 3 days no matter what are you put here.
            URLQueryItem(name: "lang", value: "ru"),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "no")
        ]

        guard let url = components.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
            .decode(type: ForecastWeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
