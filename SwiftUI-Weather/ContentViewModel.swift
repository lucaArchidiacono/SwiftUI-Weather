//
//  ContentViewModel.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 27.10.21.
//

import SwiftUI

struct WeatherInfo {
	let id = UUID()
	let dayOfWeek: String
	let imageName: String
	let temperature: Int
}

final class ContentViewModel: ObservableObject {
	private let networkService: NetworkService
	private let city: String
	
	private let defaultMidDayIcon: String = "cloud.sun.fill"
	private let defaultEveningIcon: String = "moon.stars.fill"
    private let iconCodes: [String: String] = [
		"01d": "sun.max.fill",
		"01n": "moon.fill",
		"02d": "cloud.sun.fill",
		"02n": "cloud.moon.fill",
		"03d": "cloud.fill",
		"03n": "cloud.fill",
		"04d": "smoke.fill",
		"04n": "smoke.fill",
		"09d": "cloud.heavyrain.fill",
		"09n": "cloud.heavyrain.fill",
		"10d": "cloud.sun.rain.fill",
		"10n": "cloud.moon.rain.fill",
		"11d": "cloud.sun.bolt.fill",
		"11n": "cloud.moon.bolt.fill",
		"13d": "snow",
		"13n": "snow",
		"50d": "cloud.fog.fill",
		"50n": "cloud.fog.fill"
	]
	private var currentMidDayWeather = WeatherInfo(dayOfWeek: "", imageName: "cloud.sun.fill", temperature: 24)
	private var currentEveningWeather = WeatherInfo(dayOfWeek: "", imageName: "moon.stars.fill", temperature: 10)
	
	var currentWeatherImage: String {
		return isNight ? currentEveningWeather.imageName : currentMidDayWeather.imageName
	}
	var currentWeatherTemp: Int {
		return isNight ? currentEveningWeather.temperature : currentMidDayWeather.temperature
	}
	@Published var isNight = false
	
	init(networkService: NetworkService, city: String = "Zurich") {
		self.networkService = networkService
		self.city = city
	}
	
	
	func fetchWeatherData(completion: @escaping ((Result<(midDay: [WeatherInfo], evening: [WeatherInfo]), Error>) -> Void)) {
		networkService.fetch(in: city) { [weak self] result in
			guard let self = self else { return }
			switch result {
			case .success(let weather):
				var midDayForecasts = weather.getForecast(for: .noon)
				let eveningForecasts = weather.getForecast(for: .evening)
				
				if let todayMidDayWeather = weather.getCurrentMidDayWeather(),
				   let todayMidDayWeatherIcon = todayMidDayWeather.weather.first?.icon {
					self.currentMidDayWeather = WeatherInfo(dayOfWeek: todayMidDayWeather.stringWeekDay,
															imageName: self.iconCodes[todayMidDayWeatherIcon, default: self.defaultMidDayIcon],
															temperature: Int(todayMidDayWeather.main.temp))
				} else if let tomorrowMidDayWeather = midDayForecasts.first,
						  let tomorrowMidDayWeatherIcon = tomorrowMidDayWeather.weather.first?.icon {
					self.currentMidDayWeather = WeatherInfo(dayOfWeek: tomorrowMidDayWeather.stringWeekDay,
															imageName: self.iconCodes[tomorrowMidDayWeatherIcon, default: self.defaultMidDayIcon],
															temperature: Int(tomorrowMidDayWeather.main.temp))
					_ = midDayForecasts.removeFirst()
				}
				
				if let todayEveningWeather = weather.getCurrentEveningWeather(),
				   let todayEveningWeatherIcon = todayEveningWeather.weather.first?.icon {
					self.currentEveningWeather = WeatherInfo(dayOfWeek: todayEveningWeather.stringWeekDay,
															 imageName: self.iconCodes[todayEveningWeatherIcon, default: self.defaultMidDayIcon],
															 temperature: Int(todayEveningWeather.main.temp))
				}
				
				self.isNight = 9..<17 ~= weather.latestListHour ? false : true
				
				completion(.success((
					midDay: self.transform(from: midDayForecasts),
					evening: self.transform(from: eveningForecasts))))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func transform(from list: [Weather.List]) -> [WeatherInfo] {
        list.compactMap {
            guard let icon = $0.weather.first?.icon, let imageName = iconCodes[icon] else { return nil }
			return WeatherInfo(dayOfWeek: $0.stringWeekDay,
							   imageName: imageName,
							   temperature: Int($0.main.temp))
        }
    }
}
