//
//  StationService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift

enum StationServiceError: ErrorType {
    case StaticStationDataNotFound
    case UnableToLoadStaticStationData
    case UnableToParseStationData
}

class StationService {
    
    private var stations: [Station] = []
    
    func getStations() -> Observable<[Station]> {

        func early(observer: AnyObserver<[Station]>, error: StationServiceError) -> Disposable {
            observer.onError(error)
            return AnonymousDisposable { }
        }
        
        return Observable.create { observer in
        
            guard let stationDataFilepath: String = NSBundle.mainBundle().pathForResource("Dublin", ofType: "json") else {
                return early(observer, error: StationServiceError.StaticStationDataNotFound)
            }
            
            guard let stationData = NSData(contentsOfFile: stationDataFilepath) else {
                return early(observer, error: StationServiceError.UnableToLoadStaticStationData)
            }
            
            guard let stationArray = try? NSJSONSerialization.JSONObjectWithData(stationData, options: NSJSONReadingOptions()) as? NSArray else {
                return early(observer, error: StationServiceError.UnableToParseStationData)
            }

            var result = [Station]()
            
            if let array = stationArray as? [[String:AnyObject]] {
                for dict in array {
                    if let station = try? Station(dict: dict) {
                        result.append(station)
                    }
                }
            }
            
            self.stations = result
            
            observer.onNext(result)

            return AnonymousDisposable { }
        }
        
    }
    
    func getNearestStations(location: CLLocation, radius: CLLocationDistance) -> [Station] {
    
        var result = [Station]()
        for station in stations {
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distance = stationLocation.distanceFromLocation(location)
            if distance <= radius {
                result.append(station)
            }
        }
        return result
        
    }

}
