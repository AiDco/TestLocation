//
//  ViewController.swift
//  TestLocation
//
//  Created by AiD on 06.05.2022.
//

import UIKit
import CoreLocation

struct TempModel: Codable, Equatable {
    let uuid: String
    var latitude: Double
    var longitude: Double
    var altitude: Double
}

class ViewController: UIViewController, CLLocationManagerDelegate, URLSessionDelegate {

    let decoder = JSONEncoder()
    var locationManager = CLLocationManager()
    var sender: URLSessionWebSocketTask?
    let uuid = UIDevice.current.identifierForVendor?.uuidString

    var isOpened = false

    let reciever = URLSession(configuration: .default).webSocketTask(with: URL(string: "wss://s3772.nyc3.piesocket.com/v3/1?api_key=Jto0ejerH5ATXguz6cWeWA58A4Zj3liorGdtZ7Lo&notify_all")!)

    var tempModel: TempModel? = nil {
        didSet {
            let encodedData = try! decoder.encode(tempModel)
            let data = Data(encodedData)
            let message = URLSessionWebSocketTask.Message.data(data)
            sender?.send(message) { error in
              if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
              }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sender = URLSession(configuration: .default).webSocketTask(with: URL(string: "wss://s3772.nyc3.piesocket.com/v3/1?api_key=Jto0ejerH5ATXguz6cWeWA58A4Zj3liorGdtZ7Lo&notify_all")!)
        sender?.resume()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        reciever.resume()
        receiveMessage()
        
    }

    func receiveMessage() {
        reciever.receive(completionHandler: { [weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let message):
                switch message {
                case .string(let messageString):
                    print(messageString)
                case .data(let data):
                    print(data.description)
                default:
                    print("Unknown type received from WebSocket")
                }
            }
            self?.receiveMessage()
        })
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, let uuid = uuid {
            let model = TempModel(uuid: uuid, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
            if model != tempModel {
                tempModel = model
            }
        }
    }
}

