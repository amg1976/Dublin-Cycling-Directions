//
//  StationServiceTests.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import XCTest
@testable import Dublin_Cycling_Directions
@testable import Pods_Dublin_Cycling_Directions

class StationServiceTests: XCTestCase {
    
    func testCanLoadStaticStations() {
        let stationService = StationService()
        guard let allStations: [Station] = try? stationService.getStations() else {
            XCTAssertFalse(true)
            return
        }
        XCTAssertEqual(allStations.count, 101)
    }
    
}
