//
//  ContentView.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 26.10.21.
//

import SwiftUI

struct ContentView: View {
    private struct StaticWeather {
        let id = UUID()
        let dayOfWeek: String
        let imageName: String
        let temperature: Int
    }
    
    private let city = "Zurich"
    private let defaultMidDayIcon = "cloud.sun.fill"
    private let defaultEveningIcon = "moon.stars.fill"
    private let iconCodes: [String: String] = ["01d": "sun.max.fill", "01n": "moon.fill",
                                               "02d": "cloud.sun.fill", "02n": "cloud.moon.fill",
                                               "03d": "cloud.fill", "03n": "cloud.fill",
                                               "04d": "smoke.fill", "04n": "smoke.fill",
                                               "09d": "cloud.heavyrain.fill", "09n": "cloud.heavyrain.fill",
                                               "10d": "cloud.sun.rain.fill", "10n": "cloud.moon.rain.fill",
                                               "11d": "cloud.sun.bolt.fill", "11n": "cloud.moon.bolt.fill",
                                               "13d": "snow", "13n": "snow",
                                               "50d": "cloud.fog.fill", "50n": "cloud.fog.fill"]
    
    @State private var currentMidDayWeather = StaticWeather(dayOfWeek: "", imageName: "cloud.sun.fill", temperature: 24)
    @State private var currentEveningWeather = StaticWeather(dayOfWeek: "", imageName: "moon.stars.fill", temperature: 10)
    @State private var midDayForecastWeatherList = [StaticWeather]()
    @State private var eveningForecastWeatherList = [StaticWeather]()
    @State private var isNight = false
    
    var body: some View {
        ZStack {
            BackgroundView(isNight: $isNight)
            VStack {
                CityTextView(cityName: "\(city), ZH")
                
                MainWeatherStatusView(imageName: isNight ? currentEveningWeather.imageName : currentMidDayWeather.imageName,
                                      temperatur: isNight ? currentEveningWeather.temperature : currentMidDayWeather.temperature)
                
                HStack(spacing: 20) {
                    if isNight {
                        ForEach(eveningForecastWeatherList, id: \.id) { weather in
                            WeatherDayView(dayOfWeek: weather.dayOfWeek,
                                           imageName: weather.imageName,
                                           temperature: weather.temperature)
                        }
                    } else {
                        ForEach(midDayForecastWeatherList, id: \.id) { weather in
                            WeatherDayView(dayOfWeek: weather.dayOfWeek,
                                           imageName: weather.imageName,
                                           temperature: weather.temperature)
                        }
                    }
                }
                Spacer()
                Button {
                    isNight.toggle()
                } label: {
                    WeatherButton(title: "Change Day Time", textColor: .blue, backgroundColor: .white)
                }
                Spacer()
            }
        }.onAppear(perform: {
            Api().fetchWeatherData(location: city) { result in
                switch result {
                case .success(let weather):
                    guard let currentMidDayWeather = weather.forecastMidDayList.dropFirst().first,
                          let currentEveningWeather = weather.forecastEveningList.dropFirst().first,
                          let currentMidDayIcon = currentMidDayWeather.weather.first?.icon,
                          let currentEveningIcon = currentEveningWeather.weather.first?.icon else { return }
                    
                    self.currentMidDayWeather = StaticWeather(dayOfWeek: currentMidDayWeather.weekDay,
                                                              imageName: iconCodes[currentMidDayIcon, default: defaultMidDayIcon],
                                                              temperature: Int(currentMidDayWeather.main.temp))
                    self.currentEveningWeather = StaticWeather(dayOfWeek: currentEveningWeather.weekDay,
                                                              imageName: iconCodes[currentEveningIcon, default: defaultEveningIcon],
                                                              temperature: Int(currentEveningWeather.main.temp))
                    
                    self.midDayForecastWeatherList = getWeatherList(from: weather.forecastMidDayList)
                    self.eveningForecastWeatherList = getWeatherList(from: weather.forecastEveningList)
                case .failure(let error):
                    print(error)
                }
            }
        })
    }
    
    private func getTodayWeekDay() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let weekDay = dateFormatter.string(from: Date())
        return weekDay.prefix(3).uppercased()
    }
    
    private func getWeatherList(from list: [Weather.List]) -> [StaticWeather] {
        list.compactMap {
            guard let icon = $0.weather.first?.icon, let imageName = iconCodes[icon] else { return nil }
            return StaticWeather(dayOfWeek: $0.weekDay,
                                 imageName: imageName,
                                 temperature: Int($0.main.temp))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WeatherDayView: View {
    var dayOfWeek: String
    var imageName: String
    var temperature: Int
    
    var body: some View {
        VStack {
            Text(dayOfWeek)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            Text("\(temperature)°C")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct BackgroundView: View {
    
    @Binding var isNight: Bool
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [isNight ? .black : .blue,
                                                   isNight ? .gray : Color("lightBlue")]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
    }
}

struct CityTextView: View {
    var cityName: String
    
    var body: some View {
        Text(cityName)
            .font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(.white)
            .padding()
    }
}

struct MainWeatherStatusView: View {
    var imageName: String
    var temperatur: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            Text("\(temperatur)°C")
                .font(.system(size: 70, weight: .medium))
                .foregroundColor(.white)
        }.padding(.bottom, 40)
    }
}
