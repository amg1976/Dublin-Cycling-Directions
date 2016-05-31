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
    private var selectedPlace: Variable<GMSPlace?> = Variable(nil)
    
    @IBAction func touchedSearchButton(sender: AnyObject) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        self.presentViewController(acController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMap()
        
        let stationsObservable = stationService.getStations()
        let selectedPlaceObservable = selectedPlace.asObservable()
        
        Observable.combineLatest(selectedPlaceObservable, stationsObservable) { [weak self] (place, stations) -> (CLLocation?,[Station]) in
            
            guard let strongSelf = self, place = place else { return (nil, []) }
            
            return (place.coordinate.getCLLocation(), strongSelf.stationService.getNearestStations(place.coordinate.getCLLocation(), radius: Constants.stationsMinimunDistance))

        }.subscribeNext { [weak self] (location, closestStations) in
            
            guard let location = location else { return }
            
            self?.showLocationAndNearestStations(location, stations: closestStations)

        }.addDisposableTo(disposeBag)

    }

}

extension ViewController {

    private func setupMap() {
    
        let camera = GMSCameraPosition.cameraWithLatitude(Constants.dublinCoords.coordinate.latitude,
                                                          longitude: Constants.dublinCoords.coordinate.longitude, zoom: Constants.mapDefaultZoom)
        
        let mapView = GMSMapView.mapWithFrame(CGRect.zero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.delegate = self
        mapView.settings.myLocationButton = true
        self.view = mapView
        
        LocationService.sharedInstance.lastLocation.asObservable().subscribeNext { [weak self] (location) in
            print(location)
            switch location {
            case .Available(let location):
                self?.mapView?.animateToLocation(location.coordinate)
            default:
                break
            }
        }.addDisposableTo(disposeBag)

    }
    
    private func showLocationAndNearestStations(location: CLLocation, stations: [Station]) {

        mapView?.clear()

        let camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: Constants.mapDefaultZoom)
        mapView?.camera = camera
        
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
    
    func mapView(mapView: GMSMapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        print(coordinate)
    }
    
}

extension ViewController: GMSAutocompleteViewControllerDelegate {

    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        selectedPlace.value = place
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        
    }
    
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
