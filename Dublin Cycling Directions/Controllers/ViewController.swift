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
    private lazy var mapView: GMSMapView? = { return self.view as? GMSMapView }()
    private var directionService = DirectionsService()
    private var stationService = StationService()
    
    private var selectedMarkers: [GMSMarker] = [GMSMarker]()
    private var addedPolyline: GMSPolyline?

    private var selectedPlace: Property<GMSPlace?> = Property<GMSPlace?>(nil)
    
    @IBAction func touchedSearchButton(sender: AnyObject) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        self.presentViewController(acController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMap()
        
        guard let _ = mapView else { return }
        
        selectedPlace.observeNext { [weak self] (place) in

            guard let place = place, strongSelf = self else { return }
            
            let location = place.coordinate.getCLLocation()
            strongSelf.stationService.getNearestStations(location, radius: Constants.stationsMinimunDistance).observeNext({ (stations) in
                
                strongSelf.showLocationAndNearestStations(location, stations: stations)
                
            }).disposeIn(strongSelf.disposeBag)
                
            
        }.disposeIn(disposeBag)

        /*
        Observable.combineLatest(currentLocationObservable, selectedMarkerObservable, resultSelector: { (currentLocation, selectedMarker) -> GMSPolyline? in
            
            guard let selectedMarker = selectedMarker else { return nil }
            
            switch currentLocation {
            case .Available(let location):
                DirectionsService().getDirections(location.coordinate, destination: selectedMarker.position) { (polyline, error) in

                }
                return nil
            default:
                return nil
            }
            
        }).subscribeNext { (polyline) in
            
        }.addDisposableTo(disposeBag)
         */

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

        let locationStream = LocationService.sharedInstance.lastLocation
        
        locationStream.observeNext({ [weak self] (location) in
            
            print(location)
            switch location {
            case .Available(let location):
                self?.mapView?.animateToLocation(location.coordinate)
            default:
                break
            }
        
        }).disposeIn(disposeBag)
        
        let latestRoute = mapView.tappedMarker.combineLatestWith(locationStream).flatMapMerge { [weak self] (selectedMarker, currentLocation) -> Operation<GMSPolyline?, DirectionsServiceError<NSError>> in
        
            guard let strongSelf = self,
                location = currentLocation.value(),
                selectedMarker = selectedMarker
                else {
                    return Operation<GMSPolyline?, DirectionsServiceError<NSError>>.just(nil)
            }
            
            print("tapped: \(selectedMarker), location: \(location)")
            return strongSelf.directionService.getDirections(location.coordinate, destination: selectedMarker.position)

        }
        
        latestRoute.zipPrevious().observeNext { [weak self] (previous, last) in
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

extension GMSMapView {

    var rDelegate: ProtocolProxy {
        return protocolProxyFor(GMSMapViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
    }
    
    var tappedMarker: Stream<GMSMarker?> {
        return rDelegate.streamFor(#selector(GMSMapViewDelegate.mapView(_:didTapMarker:))) { (mapView: GMSMapView, marker: GMSMarker) in marker }
    }
    
}

/*
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
 */

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
