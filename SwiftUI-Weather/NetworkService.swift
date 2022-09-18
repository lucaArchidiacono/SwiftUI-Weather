//
//  NetworkService.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 16.09.22.
//

import Foundation

protocol NetworkService {
    func fetch(in location: String, completion: @escaping ((Result<Weather, Error>) -> Void))
}

final class NetworkServiceImpl: NetworkService {
	func fetch(in location: String, completion: @escaping ((Result<Weather, Error>) -> Void)) {
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
