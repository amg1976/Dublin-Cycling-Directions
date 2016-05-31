//
//  StationService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import RxSwift

enum StationServiceError: ErrorType {
    case StaticStationDataNotFound
    case UnableToLoadStaticStationData
    case UnableToParseStationData
}

struct StationService {

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
            
            observer.onNext(result)

            return AnonymousDisposable { }
        }
        
    }

}
