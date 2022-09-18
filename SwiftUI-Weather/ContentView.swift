//
//  ContentView.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 26.10.21.
//

import SwiftUI

class Information {
	static let city = "Zurich"
	static let alert = "Oops something went wrong!\nPlease restart the application :D"
	static let changeDayTimeTitle = "Change Day Time"
}

struct ContentView: View {
	@State private var midDayForecastWeatherList = [WeatherInfo]()
	@State private var eveningForecastWeatherList = [WeatherInfo]()
	@State private var isLoading = true
	@State private var showAlert = false
	
	@StateObject var viewModel = ContentViewModel(networkService: NetworkServiceImpl(),
												  city: Information.city)
	
	var body: some View {
		ZStack {
			BackgroundView(viewModel: viewModel)
			if isLoading {
				LoadingView(isLoading: $isLoading)
			} else {
				if showAlert {
					Text(Information.alert)
				} else {
					VStack {
						CityTextView(cityName: "\(Information.city)")
						
						MainWeatherStatusView(
							imageName: viewModel.currentWeatherImage,
							temperatur: viewModel.currentWeatherTemp)
						
						HStack(spacing: 20) {
							if viewModel.isNight {
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
							viewModel.isNight.toggle()
						} label: {
							WeatherButton(title: Information.changeDayTimeTitle,
										  textColor: .blue,
										  backgroundColor: .white)
						}
						Spacer()
					}
				}
			}
		}.onAppear(perform: {
			isLoading = true
			viewModel.fetchWeatherData { result in
				isLoading = false
				switch result {
				case let .success((midDayForecasts, eveningForecasts)):
					midDayForecastWeatherList = midDayForecasts
					eveningForecastWeatherList = eveningForecasts
				case .failure(let error):
					print(error)
					showAlert = true
				}
			}
		})
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
	@ObservedObject var viewModel: ContentViewModel
	
	var body: some View {
		LinearGradient(gradient: Gradient(colors: [viewModel.isNight ? .black : .blue,
												   viewModel.isNight ? .gray : Color("lightBlue")]),
					   startPoint: .topLeading,
					   endPoint: .bottomTrailing)
		.edgesIgnoringSafeArea(.all)
	}
}

struct CityTextView: View {
	let cityName: String
	
	var body: some View {
		Text(cityName)
			.font(.system(size: 32, weight: .medium, design: .default))
			.foregroundColor(.white)
			.padding()
	}
}

struct MainWeatherStatusView: View {
	let imageName: String
	let temperatur: Int
	
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
