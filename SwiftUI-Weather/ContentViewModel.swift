//
//  ContentViewModel.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 27.10.21.
//

import Foundation

struct Weather: Codable {
    let cod: String
    let message, cnt: Int
    let list: [List]
    let city: City
    
    enum Day {
        case noon
        case evening
    }
    
    var latestListHour: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return Calendar.current.component(.hour, from: dateFormatter.date(from: list.first!.dtTxt)!)
    }
    
    func getCurrentMidDayWeather() -> List? {
        return list.first { list in
            return 9..<17 ~= latestListHour
        }
    }
    
    func getCurrentEveningWeather() -> List? {
        return list.first { list in
            return 17..<24 ~= latestListHour
        }
    }
    
    func getForecast(for day: Day) -> [List] {
        var previousDate = Calendar.current.component(.weekday, from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return list.compactMap { list in
            if previousDate == list.componentWeekDay {
                return nil
            } else {
                let hour = Calendar.current.component(.hour, from: dateFormatter.date(from: list.dtTxt)!)
                switch day {
                case .noon:
                    if 9..<17 ~= hour {
                        previousDate = list.componentWeekDay
                        return list
                    }
                case .evening:
                    if 17..<24 ~= hour {
                        previousDate = list.componentWeekDay
                        return list
                    }
                }
                return nil
            }
        }
    }

    // MARK: - City
    struct City: Codable {
        let id: Int
        let name: String
        let coord: Coord
        let country: String
        let timezone, sunrise, sunset: Int
    }

    // MARK: - Coord
    struct Coord: Codable {
        let lat, lon: Double
    }

    // MARK: - List
    struct List: Codable {
        let dt: Double
        let main: Main
        let weather: [Weather]
        let clouds: Clouds
        let wind: Wind
        let visibility: Int
        let pop: Double
        let rain: Rain?
        let sys: Sys
        let dtTxt: String

        enum CodingKeys: String, CodingKey {
            case dt, main, weather, clouds, wind, visibility, pop, rain, sys
            case dtTxt = "dt_txt"
        }
        
        var stringWeekDay: String {
            let time = Date(timeIntervalSince1970: dt)
            var cal = Calendar(identifier: .gregorian)
            if let tz = TimeZone(identifier: "Europe/Berlin") {
                cal.timeZone = tz
            }
            let weekday = (cal.component(.weekday, from: time) + 0 - 1) % 7
            return Calendar.current.weekdaySymbols[weekday].prefix(3).uppercased()
        }
        
        var componentWeekDay: Int {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return Calendar.current.component(.weekday, from: dateFormatter.date(from: dtTxt)!)
        }
    }

    // MARK: - Clouds
    struct Clouds: Codable {
        let all: Int
    }

    // MARK: - Main
    struct Main: Codable {
        let temp, feelsLike, tempMin, tempMax: Double
        let pressure, seaLevel, grndLevel, humidity: Int
        let tempKf: Double

        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case pressure
            case seaLevel = "sea_level"
            case grndLevel = "grnd_level"
            case humidity
            case tempKf = "temp_kf"
        }
    }

    // MARK: - Rain
    struct Rain: Codable {
        let the3H: Double

        enum CodingKeys: String, CodingKey {
            case the3H = "3h"
        }
    }

    // MARK: - Sys
    struct Sys: Codable {
        let pod: String
    }

    // MARK: - Weather
    struct Weather: Codable {
        let id: Int
        let main, weatherDescription, icon: String

        enum CodingKeys: String, CodingKey {
            case id, main
            case weatherDescription = "description"
            case icon
        }
    }

    // MARK: - Wind
    struct Wind: Codable {
        let speed: Double
        let deg: Int
        let gust: Double
    }

}

class Api: ObservableObject {    
    func fetchWeatherData(location: String, completion: @escaping ((Result<Weather, Error>) -> Void)) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(location)&units=metric&appid=e4e0efdce020c06b13d3dc8cd3950259"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                completion(.failure(error))
                return
            }
            
            let decoder = JSONDecoder()
            
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
            
            do {
                let weather = try decoder.decode(Weather.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(weather))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
