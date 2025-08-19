import Foundation

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case invalidResponse(status: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных"
        case .decodingError:
            return "Ошибка при обработке данных"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse(let status, let message):
            return "Неверный ответ от сервера (\(status))\(message != nil ? ": \(message!)" : "")"
        }
    }
}

class WeatherService {
    private let apiKey = "7a7a8cc2106241cf885144637251008"
    private let baseURL = "https://api.weatherapi.com/v1"
    
    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.path = "/v1\(path)"
        components?.queryItems = queryItems
        return components?.url
    }
    
    private func request(_ url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse(status: -1, message: nil)
            }
            guard http.statusCode == 200 else {
                let message = String(data: data, encoding: .utf8)
                print("Weather API error status=\(http.statusCode), body=\(message ?? "<nil>")")
                throw WeatherError.invalidResponse(status: http.statusCode, message: message)
            }
            return data
        } catch let error as WeatherError {
            throw error
        } catch {
            throw WeatherError.networkError(error)
        }
    }
    
    func fetchCurrentWeather(for location: String) async throws -> WeatherResponse {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let query: [URLQueryItem] = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "aqi", value: "no")
        ]
        guard let url = makeURL(path: "/current.json", queryItems: query) else {
            throw WeatherError.invalidURL
        }
        let data = try await request(url)
        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch {
            print("Ошибка декодирования: \(error)")
            throw WeatherError.decodingError
        }
    }
    
    func fetchForecast(for location: String, days: Int = 3) async throws -> WeatherResponse {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let query: [URLQueryItem] = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "no")
        ]
        guard let url = makeURL(path: "/forecast.json", queryItems: query) else {
            throw WeatherError.invalidURL
        }
        let data = try await request(url)
        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch {
            print("Ошибка декодирования: \(error)")
            throw WeatherError.decodingError
        }
    }
    
    func fetchHourlyForecast(for location: String, days: Int = 1) async throws -> WeatherResponse {
        return try await fetchForecast(for: location, days: days)
    }
}
