//
//  LocationService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 30/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveKit

enum LocationServiceState<T> {
    case Unknown
    case Loading
    case Failed
    case Stopped
    case Available(T)
    
    func value() -> T? {
        switch self {
        case .Available(let location):
            return location
        default:
            return nil
        }
    }
}

class LocationService: NSObject {

    private var manager: CLLocationManager
    
    private (set) var lastLocation: Property<LocationServiceState<CLLocation>> = Property<LocationServiceState<CLLocation>>(.Unknown)
    
    static let sharedInstance = LocationService()
    
    private override init() {
        manager = CLLocationManager()
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 100
        
    }
    
    func startMonitoring() {
        lastLocation.value = .Loading
        manager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        lastLocation.value = .Stopped
        manager.stopUpdatingLocation()
    }
    
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        lastLocation.value = .Failed
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            self.lastLocation.value = .Failed
            return
        }

        self.lastLocation.value = .Available(lastLocation)

    }
    
}
