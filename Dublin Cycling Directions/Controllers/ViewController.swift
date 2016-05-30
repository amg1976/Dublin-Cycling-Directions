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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let camera = GMSCameraPosition.cameraWithLatitude(Constants.dublinCoords.coordinate.latitude,
                                                          longitude: Constants.dublinCoords.coordinate.longitude, zoom: 15)

        let mapView = GMSMapView.mapWithFrame(CGRect.zero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.delegate = self
        self.view = mapView

        if let stations = try? StationService().getStations() {
            for station in stations {
                let marker = GMSMarker()
                marker.position = station.location
                marker.title = station.name
                marker.map = mapView
            }
        }
        
        LocationService.sharedInstance.lastLocation.asObservable().subscribeNext { (locationState) in
            print(locationState)
            if let view = self.view as? GMSMapView {
                switch locationState {
                case .Available(let location):
                    view.animateToLocation(location.coordinate)
                default:
                    break
                }
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
