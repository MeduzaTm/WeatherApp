import UIKit

final class WeatherViewController: UIViewController {
    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let searchContainerView = UIView()
    private let searchTextField = UITextField()
    private let searchButton = UIButton(type: .system)
    private let weatherCardView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // Logic
    private let viewModel = WeatherViewModel()
    private let locationService = LocationService()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()

        Task {
            do {
                let coordQuery = try await locationService.getCurrentCoordinatesQuery()
                await viewModel.loadForecast(for: coordQuery, days: 10)
            } catch {
                await viewModel.loadForecast(for: "Moscow", days: 10)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupGradientBackground(for: .cloudy)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }

    // MARK: - Gradient
    private func setupGradientBackground(for weatherType: WeatherType) {
        DispatchQueue.main.async {
            if let existingGradient = self.view.layer.sublayers?.first as? CAGradientLayer {
                existingGradient.removeFromSuperlayer()
            }
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.view.bounds
            switch weatherType {
            case .cloudy:
                gradientLayer.colors = [
                    UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).cgColor,
                    UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0).cgColor,
                    UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0).cgColor
                ]
            case .sunny:
                gradientLayer.colors = [
                    UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).cgColor,
                    UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0).cgColor
                ]
            case .rainy:
                gradientLayer.colors = [
                    UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor,
                    UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0).cgColor,
                    UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1.0).cgColor
                ]
            case .snowy:
                gradientLayer.colors = [
                    UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0).cgColor,
                    UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0).cgColor
                ]
            }
            gradientLayer.locations = [0.0, 0.5, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            self.view.layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    // MARK: - UI setup
    private func setupUI() {
        view.backgroundColor = .clear
        title = "Weather App"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.isHidden = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        searchContainerView.translatesAutoresizingMaskIntoConstraints = false

        searchTextField.placeholder = "Enter the city..."
        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        searchTextField.textColor = .white
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter the city...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        )
        searchTextField.autocapitalizationType = .none
        searchTextField.autocorrectionType = .no
        searchTextField.font = UIFont.systemFont(ofSize: 16)
        searchTextField.layer.cornerRadius = 25
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        searchTextField.leftViewMode = .always
        searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        searchTextField.rightViewMode = .always
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.addTarget(self, action: #selector(searchTextFieldDidChange), for: .editingChanged)
        searchTextField.delegate = self

        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        searchButton.layer.cornerRadius = 25
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)

        weatherCardView.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white

        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        errorView.layer.cornerRadius = 20
        errorView.layer.borderWidth = 1
        errorView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        errorView.isHidden = true

        errorLabel.text = "Error"
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.textColor = .white
        errorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        retryButton.setTitle("Try again", for: .normal)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        retryButton.layer.cornerRadius = 20
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)

        searchContainerView.addSubview(searchTextField)
        searchContainerView.addSubview(searchButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(searchContainerView)
        contentView.addSubview(weatherCardView)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(errorView)
        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            searchContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            searchContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            searchContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            searchContainerView.heightAnchor.constraint(equalToConstant: 60),

            searchTextField.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),

            searchButton.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchButton.leadingAnchor.constraint(equalTo: searchTextField.trailingAnchor, constant: 12),
            searchButton.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            searchButton.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 100),

            weatherCardView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 30),
            weatherCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weatherCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weatherCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -20),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            retryButton.bottomAnchor.constraint(equalTo: errorView.bottomAnchor, constant: -20),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func setupBindings() {
        viewModel.delegate = self
    }

    // MARK: - Update UI
    private func updateWeatherUI() {
        guard let weather = viewModel.currentWeather else { return }
        let weatherType = determineWeatherType(from: weather.current.condition.text)
        DispatchQueue.main.async {
            self.setupGradientBackground(for: weatherType)
            let weatherCard = self.createWeatherCard(weather: weather, weatherType: weatherType)
            self.weatherCardView.subviews.forEach { $0.removeFromSuperview() }
            self.weatherCardView.addSubview(weatherCard)
            weatherCard.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                weatherCard.topAnchor.constraint(equalTo: self.weatherCardView.topAnchor),
                weatherCard.leadingAnchor.constraint(equalTo: self.weatherCardView.leadingAnchor),
                weatherCard.trailingAnchor.constraint(equalTo: self.weatherCardView.trailingAnchor),
                weatherCard.bottomAnchor.constraint(equalTo: self.weatherCardView.bottomAnchor)
            ])
            self.errorView.isHidden = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.weatherCardView.alpha = 1
            }
        }
    }

    private func updateLoadingUI() {
        DispatchQueue.main.async {
            if self.viewModel.isLoading {
                self.activityIndicator.startAnimating()
                self.weatherCardView.isHidden = true
                self.weatherCardView.alpha = 0
            } else {
                self.activityIndicator.stopAnimating()
                self.weatherCardView.isHidden = false
            }
        }
    }

    private func updateErrorUI() {
        DispatchQueue.main.async {
            if let errorMessage = self.viewModel.errorMessage {
                self.errorLabel.text = errorMessage
                self.errorView.isHidden = false
                self.weatherCardView.isHidden = true
            } else {
                self.errorView.isHidden = true
            }
        }
    }

    enum WeatherType { case cloudy, sunny, rainy, snowy }

    private func determineWeatherType(from condition: String) -> WeatherType {
        let lowercased = condition.lowercased()
        if lowercased.contains("sun") || lowercased.contains("clear") { return .sunny }
        if lowercased.contains("rain") || lowercased.contains("drizzle") || lowercased.contains("shower") { return .rainy }
        if lowercased.contains("snow") || lowercased.contains("sleet") || lowercased.contains("blizzard") { return .snowy }
        return .cloudy
    }

    private func createWeatherCard(weather: WeatherResponse, weatherType: WeatherType) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        containerView.layer.cornerRadius = 30
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing

        let todayLabel = UILabel()
        todayLabel.text = "Today"
        todayLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        todayLabel.textColor = getTextColor(for: weatherType)


        headerStack.addArrangedSubview(todayLabel)

        // Big info
        let weatherInfoStack = UIStackView()
        weatherInfoStack.axis = .horizontal
        weatherInfoStack.spacing = 20
        weatherInfoStack.alignment = .center

        let weatherIcon = UILabel()
        weatherIcon.text = getWeatherIcon(for: weatherType)
        weatherIcon.font = UIFont.systemFont(ofSize: 60)

        let bigTempLabel = UILabel()
        bigTempLabel.text = "\(Int(round(weather.current.tempC)))°"
        bigTempLabel.font = UIFont.systemFont(ofSize: 72, weight: .thin)
        bigTempLabel.textColor = getTextColor(for: weatherType)

        weatherInfoStack.addArrangedSubview(weatherIcon)
        weatherInfoStack.addArrangedSubview(bigTempLabel)

        // Details
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 8
        detailsStack.alignment = .leading

        let conditionLabel = UILabel()
        conditionLabel.text = weather.current.condition.text
        conditionLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        conditionLabel.textColor = getTextColor(for: weatherType)

        let locationLabel = UILabel()
        locationLabel.text = "\(weather.location.region), \(weather.location.name)"
        locationLabel.font = UIFont.systemFont(ofSize: 16)
        locationLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)

        let dateLabel = UILabel()
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        dateLabel.text = df.string(from: Date())
        dateLabel.font = UIFont.systemFont(ofSize: 16)
        dateLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)

        let feelsLikeLabel = UILabel()
        feelsLikeLabel.text = "Feels like \(Int(round(weather.current.feelslikeC)))°"
        feelsLikeLabel.font = UIFont.systemFont(ofSize: 16)
        feelsLikeLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)

        let sunsetLabel = UILabel()
        if let forecastDay = weather.forecast?.forecastday.first {
            sunsetLabel.text = "Sunset: \(forecastDay.astro.sunset)"
        }
        sunsetLabel.font = UIFont.systemFont(ofSize: 16)
        sunsetLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)

        detailsStack.addArrangedSubview(conditionLabel)
        detailsStack.addArrangedSubview(locationLabel)
        detailsStack.addArrangedSubview(dateLabel)
        detailsStack.addArrangedSubview(feelsLikeLabel)
        detailsStack.addArrangedSubview(sunsetLabel)

        // Hourly
        let hourlyStack = UIStackView()
        hourlyStack.axis = .vertical
        hourlyStack.spacing = 15

        let hourlyTitle = UILabel()
        hourlyTitle.text = "Hourly Forecast"
        hourlyTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        hourlyTitle.textColor = getTextColor(for: weatherType)

        let nextHours = getNextHours(from: weather, count: 10)
        let firstRow = Array(nextHours.prefix(5))
        let secondRow = Array(nextHours.dropFirst(5).prefix(5))

        let hourlyRow1 = createHourlyRow(hours: firstRow, weatherType: weatherType)
        let hourlyRow2 = createHourlyRow(hours: secondRow, weatherType: weatherType)

        hourlyStack.addArrangedSubview(hourlyTitle)
        hourlyStack.addArrangedSubview(hourlyRow1)
        hourlyStack.addArrangedSubview(hourlyRow2)

        // 10 days
        let tenDaysView = createTenDaysForecastView(days: getTenDays(from: weather), weatherType: weatherType)

        // stack
        stackView.addArrangedSubview(headerStack)
        stackView.addArrangedSubview(weatherInfoStack)
        stackView.addArrangedSubview(detailsStack)
        stackView.addArrangedSubview(hourlyStack)
        stackView.addArrangedSubview(tenDaysView)

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])

        return containerView
    }

    private func getWeatherIcon(for weatherType: WeatherType) -> String {
        switch weatherType {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .snowy: return "❄️"
        }
    }

    private func getTextColor(for weatherType: WeatherType) -> UIColor {
        switch weatherType {
        case .sunny: return .black
        case .cloudy: return .white
        case .rainy: return .white
        case .snowy: return .white
        }
    }

    private func createHourlyRow(hours: [Hour], weatherType: WeatherType) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .fillEqually
        rowStack.spacing = 10
        for (index, hour) in hours.enumerated() {
            let hourStack = UIStackView()
            hourStack.axis = .vertical
            hourStack.alignment = .center
            hourStack.spacing = 6
            let timeLabel = UILabel()
            timeLabel.text = index == 0 ? "Now" : formatHour(epoch: hour.timeEpoch)
            timeLabel.font = UIFont.systemFont(ofSize: 14)
            timeLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)
            timeLabel.textAlignment = .center
            let tempLabel = UILabel()
            tempLabel.text = "\(Int(round(hour.tempC)))°"
            tempLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            tempLabel.textColor = getTextColor(for: weatherType)
            tempLabel.textAlignment = .center
            hourStack.addArrangedSubview(timeLabel)
            hourStack.addArrangedSubview(tempLabel)
            rowStack.addArrangedSubview(hourStack)
        }
        return rowStack
    }

    private func formatHour(epoch: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epoch))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func getNextHours(from weather: WeatherResponse, count: Int) -> [Hour] {
        guard let forecast = weather.forecast else { return [] }
        let allHours: [Hour] = forecast.forecastday.flatMap { $0.hour }
        let nowEpoch = Int(Date().timeIntervalSince1970)
        let futureHours = allHours.filter { $0.timeEpoch >= nowEpoch }
        if futureHours.count >= count { return Array(futureHours.prefix(count)) }
        return futureHours
    }

    private func getTenDays(from weather: WeatherResponse) -> [ForecastDay] {
        guard let forecast = weather.forecast else { return [] }
        return Array(forecast.forecastday.prefix(10))
    }

    private func createTenDaysForecastView(days: [ForecastDay], weatherType: WeatherType) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel()
        title.text = "10 Days Forecast"
        title.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        title.textColor = getTextColor(for: weatherType)
        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = 8
        listStack.translatesAutoresizingMaskIntoConstraints = false
        for day in days { listStack.addArrangedSubview(createDayRow(day: day, weatherType: weatherType)) }
        let v = UIStackView(arrangedSubviews: [title, listStack])
        v.axis = .vertical
        v.spacing = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: container.topAnchor),
            v.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func createDayRow(day: ForecastDay, weatherType: WeatherType) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        row.layer.cornerRadius = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        let dateLabel = UILabel()
        dateLabel.text = formatDay(dateString: day.date)
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = getTextColor(for: weatherType)
        let condLabel = UILabel()
        condLabel.text = day.day.condition.text
        condLabel.font = UIFont.systemFont(ofSize: 14)
        condLabel.textColor = getTextColor(for: weatherType).withAlphaComponent(0.8)
        condLabel.numberOfLines = 1
        let tempsLabel = UILabel()
        tempsLabel.text = "\(Int(round(day.day.mintempC)))° / \(Int(round(day.day.maxtempC)))°"
        tempsLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        tempsLabel.textColor = getTextColor(for: weatherType)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        hStack.addArrangedSubview(dateLabel)
        hStack.addArrangedSubview(condLabel)
        hStack.addArrangedSubview(spacer)
        hStack.addArrangedSubview(tempsLabel)
        row.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10)
        ])
        return row
    }

    private func formatDay(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_EN")
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "EEE, d MMM"
            return formatter.string(from: date)
        }
        return dateString
    }

    @objc private func searchTextFieldDidChange() { }

    @objc private func searchButtonTapped() {
        guard let city = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty else {
            searchTextField.shake(); return
        }
        searchTextField.resignFirstResponder()
        Task { await viewModel.loadForecast(for: city, days: 10) }
    }

    @objc private func retryButtonTapped() {
        viewModel.clearError()
        Task {
            do {
                let coordQuery = try await locationService.getCurrentCoordinatesQuery()
                await viewModel.loadForecast(for: coordQuery, days: 10)
            } catch {
                await viewModel.loadForecast(for: "Moscow", days: 10)
            }
        }
    }
}

extension WeatherViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { searchButtonTapped(); return true }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
}

extension WeatherViewController: WeatherViewModelDelegate {
    func weatherDidUpdate() { updateWeatherUI() }
    func loadingStateDidChange() { updateLoadingUI() }
    func errorDidOccur(_ message: String) {
        DispatchQueue.main.async {
            self.errorLabel.text = message
            self.errorView.isHidden = false
            self.weatherCardView.isHidden = true
        }
    }
}

 
