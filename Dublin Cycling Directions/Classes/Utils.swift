//
//  Utils.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import CoreLocation

struct Constants {
    
    struct ApiKeys {
        static let GoogleMaps = "AIzaSyC18Z-EJbDY3W9TNURUX4NRBqkKDzPOscw"
        static let DublinBikes = "597893cc7ccb9ca728c23f80adeba5130fb3b42f"
    }
    
    static let dublinCoords = CLLocation(latitude: 53.3498053, longitude: -6.260309699999993)
    static let mapDefaultZoom: Float = 15
    static let stationsMinimunDistance: Double = 500

}

extension CLLocationCoordinate2D {

    func getCLLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}
