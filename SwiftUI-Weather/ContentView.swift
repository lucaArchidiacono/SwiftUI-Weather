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
    @State private var isLoading = true
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            BackgroundView(isNight: $isNight)
            if isLoading {
                LoadingView(isLoading: $isLoading)
            } else {
                if showAlert {
                    Text("Oops something went wrong!\nPlease restart the application :D")
                } else {
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
                }
            }
        }.onAppear(perform: {
            isLoading = true
            Api().fetchWeatherData(location: city) { result in
                isLoading = false
                switch result {
                case .success(let weather):
                    var midDayForecasts = weather.getForecast(for: .noon)
                    let eveningForecasts = weather.getForecast(for: .evening)

                    if let todayMidDayWeather = weather.getCurrentMidDayWeather(),
                       let todayMidDayWeatherIcon = todayMidDayWeather.weather.first?.icon {
                        self.currentMidDayWeather = StaticWeather(dayOfWeek: todayMidDayWeather.stringWeekDay,
                                                                  imageName: iconCodes[todayMidDayWeatherIcon, default: defaultMidDayIcon],
                                                                  temperature: Int(todayMidDayWeather.main.temp))
                    } else if let tomorrowMidDayWeather = midDayForecasts.first,
                              let tomorrowMidDayWeatherIcon = tomorrowMidDayWeather.weather.first?.icon {
                        self.currentMidDayWeather = StaticWeather(dayOfWeek: tomorrowMidDayWeather.stringWeekDay,
                                                                  imageName: iconCodes[tomorrowMidDayWeatherIcon, default: defaultMidDayIcon],
                                                                  temperature: Int(tomorrowMidDayWeather.main.temp))
                        _ = midDayForecasts.removeFirst()
                    }

                    if let todayEveningWeather = weather.getCurrentEveningWeather(),
                       let todayEveningWeatherIcon = todayEveningWeather.weather.first?.icon {
                        self.currentEveningWeather = StaticWeather(dayOfWeek: todayEveningWeather.stringWeekDay,
                                                                   imageName: iconCodes[todayEveningWeatherIcon, default: defaultMidDayIcon],
                                                                   temperature: Int(todayEveningWeather.main.temp))
                    }

                    isNight = 9..<17 ~= weather.latestListHour ? false : true

                    self.midDayForecastWeatherList = getWeatherList(from: midDayForecasts)
                    self.eveningForecastWeatherList = getWeatherList(from: eveningForecasts)
                case .failure(let error):
                    print(error)
                    showAlert = true
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
            return StaticWeather(dayOfWeek: $0.stringWeekDay,
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

struct LoadingView: View {
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .rotationEffect(Angle(degrees: isLoading ? 360: 0))
                    .animation(Animation.linear.repeatForever(autoreverses: false))
            }
        }
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
