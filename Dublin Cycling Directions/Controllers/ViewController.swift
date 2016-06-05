//
//  ViewController.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 22/05/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import UIKit
import GoogleMaps
import ReactiveKit

class ViewController: UIViewController {

    private let disposeBag = DisposeBag()
    
    private let directionService = DirectionsService()
    private let stationService = StationService()

    private lazy var mapView: GMSMapView? = { return self.view as? GMSMapView }()
    private let searchController: GMSAutocompleteViewController = {
        let controller = GMSAutocompleteViewController()
        return controller
    }()
    
    @IBAction func touchedSearchButton(sender: AnyObject) {
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        
        guard let mapView = mapView else { return }
        
        setupSearchController(mapView)
        
    }

}

extension ViewController {

    private func setupMap() {
    
        let camera = GMSCameraPosition.cameraWithLatitude(Constants.dublinCoords.coordinate.latitude,
                                                          longitude: Constants.dublinCoords.coordinate.longitude, zoom: Constants.mapDefaultZoom)
        
        let mapView = GMSMapView.mapWithFrame(CGRect.zero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.settings.myLocationButton = true
        self.view = mapView

        setupCurrentLocationUpdater(mapView)
        setupRouteUpdater(mapView)
        
    }
    
    private func setupCurrentLocationUpdater(mapView: GMSMapView) {
        
        LocationService.sharedInstance.lastLocation
            .observeNext({ (location) in
            
            print(location)
            switch location {
            case .Available(let location):
                mapView.animateToLocation(location.coordinate)
            default:
                break
            }
            
        }).disposeIn(disposeBag)

    }
    
    private func setupRouteUpdater(mapView: GMSMapView) {
    
        let locationStream = LocationService.sharedInstance.lastLocation

        let latestRoute = mapView.tappedMarker
            .combineLatestWith(locationStream)
            .flatMapMerge { [weak self] (selectedMarker, currentLocation) -> DirectionsServiceResult in
            
            guard let strongSelf = self,
                location = currentLocation.value(),
                selectedMarker = selectedMarker
                else {
                    return Operation<GMSPolyline?, DirectionsServiceError<NSError>>.just(nil)
            }
            
            print("tapped: \(selectedMarker), location: \(location)")
            return strongSelf.directionService.getDirections(location.coordinate, destination: selectedMarker.position)
            
        }
        
        latestRoute
            .zipPrevious()
            .observeNext { [weak self] (previous, last) in
                
            previous??.map = nil
            guard let lastRoute = last,
                mapView = self?.mapView else { return }
            
            lastRoute.map = mapView
            
            if let path = lastRoute.path {
                let cameraUpdate = GMSCameraUpdate.fitBounds(GMSCoordinateBounds(path: path))
                mapView.moveCamera(cameraUpdate)
            }
            
        }.disposeIn(disposeBag)

    }
    
    private func showLocationAndNearestStations(mapView: GMSMapView, location: CLLocation, stations: [Station]) {

        mapView.clear()

        let camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: Constants.mapDefaultZoom)
        mapView.camera = camera
        
        let marker = GMSMarker(position: location.coordinate)
        marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
        marker.map = mapView

        for station in stations {
            let marker = GMSMarker()
            marker.appearAnimation = kGMSMarkerAnimationPop
            marker.position = station.location
            marker.title = station.name
            marker.map = mapView
        }

    }
    
    private func setupSearchController(mapView: GMSMapView) {
    
        searchController.cancelled.observeNext { [weak self] (_) in
            
            self?.dismissViewControllerAnimated(true, completion: nil)
            
        }.disposeIn(disposeBag)
        
        searchController.selectedPlace.observeNext { [weak self] (place) in
            
            self?.dismissViewControllerAnimated(true, completion: nil)
            
            guard let strongSelf = self else { return }
            
            let location = place.coordinate.getCLLocation()
            strongSelf.stationService.getNearestStations(location, radius: Constants.stationsMinimunDistance).observeNext({ (stations) in
                
                strongSelf.showLocationAndNearestStations(mapView, location: location, stations: stations)
                
            }).disposeIn(strongSelf.disposeBag)

        }.disposeIn(disposeBag)
        
    }
    
}
