//
//  StationService.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation

enum StationServiceError: ErrorType {
    case StaticStationDataNotFound
    case UnableToLoadStaticStationData
    case UnableToParseStationData
}

struct StationService {

    func getStations() throws -> [Station] {

        guard let stationDataFilepath: String = NSBundle.mainBundle().pathForResource("Dublin", ofType: "json") else {
            throw StationServiceError.StaticStationDataNotFound
        }
        
        guard let stationData = NSData(contentsOfFile: stationDataFilepath) else {
            throw StationServiceError.UnableToLoadStaticStationData
        }
        
        guard let stationArray = try? NSJSONSerialization.JSONObjectWithData(stationData, options: NSJSONReadingOptions()) as? NSArray else {
            throw StationServiceError.UnableToParseStationData
        }
        
        var result = [Station]()
        
        if let array = stationArray as? [[String:AnyObject]] {
            for dict in array {
                let station = try Station(dict: dict)
                result.append(station)
            }
        }
        
        return result
        
    }

}
