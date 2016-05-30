//
//  Station.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import CoreLocation

enum StationError: ErrorType {
    case ParsedPropertyNotFound
}

struct Station {
    let number: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    var location: CLLocationCoordinate2D
    
    init(dict: [String:AnyObject]) throws {
        
        guard let _number = dict["number"] as? Int else { throw StationError.ParsedPropertyNotFound }
        self.number = _number
        
        guard let _name = dict["name"] as? String else { throw StationError.ParsedPropertyNotFound }
        self.name = _name

        guard let _address = dict["address"] as? String else { throw StationError.ParsedPropertyNotFound }
        self.address = _address
        
        guard let _latitude = dict["latitude"] as? Double else { throw StationError.ParsedPropertyNotFound }
        self.latitude = _latitude
        
        guard let _longitude = dict["longitude"] as? Double else { throw StationError.ParsedPropertyNotFound }
        self.longitude = _longitude
        
        self.location = CLLocationCoordinate2D(latitude:latitude, longitude: longitude)
    }
    
}
