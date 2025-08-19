import Foundation

protocol WeatherViewModelDelegate: AnyObject {
    func weatherDidUpdate()
    func loadingStateDidChange()
    func errorDidOccur(_ message: String)
}

enum TemperatureUnit {
    case celsius
    case fahrenheit
}

class WeatherViewModel: NSObject {
    weak var delegate: WeatherViewModelDelegate?
    
    private(set) var currentWeather: WeatherResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private let weatherService = WeatherService()
    
    func loadCurrentWeather(for location: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            delegate?.loadingStateDidChange()
        }
        
        do {
            let weather = try await weatherService.fetchCurrentWeather(for: location)
            await MainActor.run {
                currentWeather = weather
                delegate?.weatherDidUpdate()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                delegate?.errorDidOccur(error.localizedDescription)
                print("Ошибка загрузки погоды: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
            delegate?.loadingStateDidChange()
        }
    }
    
    func loadForecast(for location: String, days: Int = 3) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            delegate?.loadingStateDidChange()
        }
        
        do {
            let weather = try await weatherService.fetchForecast(for: location, days: days)
            await MainActor.run {
                currentWeather = weather
                delegate?.weatherDidUpdate()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                delegate?.errorDidOccur(error.localizedDescription)
                print("Ошибка загрузки прогноза: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
            delegate?.loadingStateDidChange()
        }
    }
    
    func loadHourlyForecast(for location: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            delegate?.loadingStateDidChange()
        }
        
        do {
            let weather = try await weatherService.fetchHourlyForecast(for: location)
            await MainActor.run {
                currentWeather = weather
                delegate?.weatherDidUpdate()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                delegate?.errorDidOccur(error.localizedDescription)
                print("Ошибка загрузки почасового прогноза: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
            delegate?.loadingStateDidChange()
        }
    }
    
    func clearError() {
        errorMessage = nil
        delegate?.weatherDidUpdate()
    }
    
    func formatTemperature(_ temp: Double, unit: TemperatureUnit = .celsius) -> String {
        switch unit {
        case .celsius:
            return "\(Int(round(temp)))°C"
        case .fahrenheit:
            return "\(Int(round(temp)))°F"
        }
    }
    
    func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        return timeString
    }
    
    func getWeatherIconURL(_ iconCode: String) -> URL? {
        return URL(string: "https:\(iconCode)")
    }
}
