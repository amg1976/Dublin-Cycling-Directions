//
//  ViewController.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import UIKit
import GoogleMaps
import RxSwift

class ViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private var selectedMarkers: [GMSMarker] = [GMSMarker]()
    private var addedPolyline: GMSPolyline?
    private lazy var mapView: GMSMapView? = { return self.view as? GMSMapView }()
    private var stationService = StationService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let camera = GMSCameraPosition.cameraWithLatitude(Constants.dublinCoords.coordinate.latitude,
                                                          longitude: Constants.dublinCoords.coordinate.longitude, zoom: 15)

        let mapView = GMSMapView.mapWithFrame(CGRect.zero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.delegate = self
        self.view = mapView
        
        Observable.combineLatest(LocationService.sharedInstance.lastLocation.asObservable(), stationService.getStations()) { [weak self] (location, stations) -> [Station] in
            guard let strongSelf = self else { return [] }
            
            switch location {
            case .Available(let location):
                strongSelf.mapView?.animateToLocation(location.coordinate)
                return strongSelf.stationService.getNearestStations(location, radius: 500)
            default:
                return []
            }

        }.subscribeNext { [weak self] (closestStations) in
            
            self?.mapView?.clear()
            for station in closestStations {
                let marker = GMSMarker()
                marker.appearAnimation = kGMSMarkerAnimationPop
                marker.position = station.location
                marker.title = station.name
                marker.map = self?.mapView
            }

        }.addDisposableTo(disposeBag)
        
    }

}

extension ViewController {

    private func removeRouteFromMap() {
        addedPolyline?.map = nil
        addedPolyline = nil
    }
    
}

extension ViewController: GMSMapViewDelegate {

    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        
        if selectedMarkers.count == 2 {
            selectedMarkers.removeAll()
            removeRouteFromMap()
        }
        
        selectedMarkers.append(marker)
        print(selectedMarkers)
        
        if selectedMarkers.count == 2 {
            DirectionsService().getDirections(selectedMarkers[0].position, destination: selectedMarkers[1].position) { (polyline, error) in
                if let polyline = polyline, mapView = self.view as? GMSMapView {
                    polyline.map = mapView
                    self.addedPolyline = polyline
                }
            }
        }
        
        return false

    }

}
