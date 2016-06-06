//
//  StationService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveKit

enum StationServiceError: ErrorType {
    case StaticStationDataNotFound
    case UnableToLoadStaticStationData
    case UnableToParseStationData
}

typealias StationServiceResult = Operation<[Station], StationServiceError>

class StationService {
    
    private var stations: [Station] = []
    
    func getStations() -> StationServiceResult {
        
        return Operation<[Station], StationServiceError> { operation in

            guard let stationDataFilepath: String = NSBundle.mainBundle().pathForResource("Dublin", ofType: "json") else {
                operation.failure(StationServiceError.StaticStationDataNotFound)
                operation.completed()
                return NotDisposable
            }
            
            guard let stationData = NSData(contentsOfFile: stationDataFilepath) else {
                operation.failure(StationServiceError.UnableToLoadStaticStationData)
                operation.completed()
                return NotDisposable
            }
            
            guard let stationArray = try? NSJSONSerialization.JSONObjectWithData(stationData, options: NSJSONReadingOptions()) as? NSArray else {
                operation.failure(StationServiceError.UnableToParseStationData)
                operation.completed()
                return NotDisposable
            }

            var result = [Station]()
            
            if let array = stationArray as? [[String:AnyObject]] {
                for dict in array {
                    if let station = try? Station(dict: dict) {
                        result.append(station)
                    }
                }
            }
            
            operation.next(result)
            operation.completed()
            
            return NotDisposable

        }
        
    }

    func getNearestStations(location: CLLocation, radius: CLLocationDistance) -> StationServiceResult {
        
        return getStations().flatMapLatest({ (stations) -> StationServiceResult in

            return Operation<[Station], StationServiceError> { operation in
                
                var result = [Station]()
                for station in stations {
                    let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
                    let distance = stationLocation.distanceFromLocation(location)
                    if distance <= radius {
                        result.append(station)
                    }
                }
                
                operation.next(result)
                operation.completed()
                
                return NotDisposable
                
            }

        })
        
    }

}
