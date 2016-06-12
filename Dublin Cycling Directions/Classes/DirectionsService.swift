//
//  DirectionsService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import Networking
import CoreLocation
import GoogleMaps
import ReactiveKit

enum DirectionsServiceError<E: NSError>: ErrorType {
    case NetworkError(E)
}

struct Route {
    var start: CLLocationCoordinate2D
    var finish: CLLocationCoordinate2D
    var polyline: GMSPolyline
}

typealias DirectionsServiceResult = Operation<Route?, DirectionsServiceError<NSError>>

struct DirectionsService {

    func getDirections(origin: CLLocationCoordinate2D,
                       destination: CLLocationCoordinate2D) -> DirectionsServiceResult {
    
        return Operation<Route?, DirectionsServiceError<NSError>> { operation in
        
            let getParams = String(format: "maps/api/directions/json?origin=%@&destination=%@&key=%@&mode=bicycling",
                origin.googleString(), destination.googleString(), Constants.ApiKeys.GoogleMaps)
            
            let networking = Networking(baseURL: "https://maps.googleapis.com/")
            networking.GET(getParams) { (JSON, error) in
                
                guard let json = JSON as? [String:AnyObject],
                    routes = json["routes"] as? [[String:AnyObject]],
                    overviewPolyline = routes[0]["overview_polyline"] as? [String:AnyObject],
                    points = overviewPolyline["points"] as? String
                    else {
                        operation.failure(.NetworkError(error!))
                        return
                }
                
                let path = GMSPath(fromEncodedPath: points)
                let polyline = GMSPolyline(path: path)
                let route = Route(start: origin, finish: destination, polyline: polyline)
                operation.next(route)
                operation.completed()
                    
                
            }
            
            return NotDisposable
            
        }
        
    }
    
}

extension CLLocationCoordinate2D {

    func googleString() -> String {
        return "\(latitude),\(longitude)"
    }
    
}
