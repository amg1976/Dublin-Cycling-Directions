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
    
    @IBAction func touchedDeleteButton(sender: AnyObject) {
        mapView?.clear()
        
        if let mapView = mapView {
            mapView.moveCamera(centerCameraOnMyLocation(mapView))
        }
    }
    
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
        
        let initialCoordinate = Constants.MapDefaults.dublinCoords.coordinate
        let camera = GMSCameraPosition.cameraWithLatitude(initialCoordinate.latitude,
                                                          longitude: initialCoordinate.longitude, zoom: Constants.MapDefaults.zoom)
        
        let mapView = GMSMapView.mapWithFrame(CGRect.zero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.settings.myLocationButton = true
        self.view = mapView
        
        setupCurrentLocationUpdater(mapView)
        setupRouteUpdater(mapView)
        setupMyLocationTappedHandler(mapView)
        
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
        
        let sourceStation = mapView.tappedMarker
            .filter { guard let marker = $0 else { return false }
                return marker.isSourceStation
        }
        
        let sourceRoute = sourceStation
            .startWith(nil)
            .combineLatestWith(LocationService.sharedInstance.lastLocation)
            .flatMapMerge { (sourceStation, currentLocation) -> Stream<CLLocation> in
                return Stream<CLLocation>() { stream in
                    if let sourceStation = sourceStation {
                        stream.next(sourceStation.position.getCLLocation())
                    } else if let currentLocation = currentLocation.value() {
                        stream.next(currentLocation)
                    }
                    stream.completed()
                    return NotDisposable
                }
        }
        
        let destinationRoute = mapView.tappedMarker
            .ignoreNil()
            .filter { return !$0.isSourceStation }
            .flatMapLatest { (marker) -> Stream<CLLocation> in
                return Stream<CLLocation>() { stream in
                    stream.next(marker.position.getCLLocation())
                    stream.completed()
                    return NotDisposable
                }
        }
        
        sourceRoute
            .combineLatestWith(destinationRoute)
            .flatMapLatest({ (start, finish) -> DirectionsServiceResult in
                return self.directionService.getDirections(start.coordinate, destination: finish.coordinate)
            })
            .zipPrevious()
            .toStream(justLogError: true)
            .combineLatestWith(sourceRoute)
            .combineLatestWith(destinationRoute)
            .observeNext({ [weak self] (routesAndStartLocation, finishLocation) in
                
                guard let currentRoute = routesAndStartLocation.0.1  else { return }
                
                let previousRoute = routesAndStartLocation.0.0
                let startLocation = routesAndStartLocation.1
                
                mapView.clear()
                previousRoute??.map = nil
                
                currentRoute.map = mapView
                
                if let path = currentRoute.path,
                    cameraUpdate = self?.centerCameraOnPath(mapView, path: path) {
                    
                    mapView.moveCamera(cameraUpdate)
                    
                }
                
                let startMarker = GMSMarker()
                startMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
                startMarker.appearAnimation = kGMSMarkerAnimationPop
                startMarker.position = startLocation.coordinate
                startMarker.map = mapView
                
                let endMarker = GMSMarker()
                endMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                endMarker.appearAnimation = kGMSMarkerAnimationPop
                endMarker.position = finishLocation.coordinate
                endMarker.map = mapView
                
                }).disposeIn(disposeBag)
        
    }
    
    private func setupMyLocationTappedHandler(mapView: GMSMapView) {
        
        mapView.tappedMyLocation
            .flatMapMerge({ [weak self] (_) -> StationServiceResult in
                
                guard let strongSelf = self,
                    myLocation = mapView.myLocation else {
                        return StationServiceResult.just([])
                }
                
                return strongSelf.stationService.getNearestStations(myLocation, radius: Constants.MapDefaults.stationsMinimunDistance)
                
                })
            .combineLatestWith(mapView.tappedMarker
                .filter { guard let marker = $0 else { return false }
                    return !marker.isSourceStation
                }
                .toOperation()
                .startWith(nil)
            )
            .observeNext({ [weak self] (stations, lastTappedMarker) in
                
                guard let myLocation = mapView.myLocation else { return }
                
                var displayStations = stations
                if let tapped = lastTappedMarker {
                    displayStations = stations.filter({ $0.location.googleString() != tapped.position.googleString() })
                }
                
                mapView.clear()
                
                self?.showLocationAndNearestStations(mapView, location: myLocation, isMyLocation: true, stations: displayStations)
                
                })
            .disposeIn(disposeBag)
        
    }
    
    private func showLocationAndNearestStations(mapView: GMSMapView, location: CLLocation, isMyLocation: Bool = false, stations: [Station]) {
        
        mapView.clear()
        
        let camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: Constants.MapDefaults.zoom)
        mapView.camera = camera
        
        var markerColor = UIColor.redColor()
        if !isMyLocation {
            let marker = GMSMarker(position: location.coordinate)
            marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
            marker.map = mapView
        } else {
            markerColor = UIColor.greenColor()
        }
        
        for station in stations {
            let marker = GMSMarker()
            marker.icon = GMSMarker.markerImageWithColor(markerColor)
            marker.appearAnimation = kGMSMarkerAnimationPop
            marker.position = station.location
            marker.title = station.name
            marker.isSourceStation = isMyLocation
            marker.map = mapView
        }
        
    }
    
    private func setupSearchController(mapView: GMSMapView) {
        
        searchController.cancelled.observeNext { [weak self] (_) in
            
            self?.dismissViewControllerAnimated(true, completion: nil)
            
            }.disposeIn(disposeBag)
        
        searchController.selectedPlace
            .combineLatestWith(mapView.tappedMarker
                .filter { guard let marker = $0 else { return false }
                    return marker.isSourceStation
                }
                .startWith(nil)
            )
            .observeNext { [weak self] (place, lastTappedMarker) in
                
                self?.dismissViewControllerAnimated(true, completion: nil)
                
                guard let strongSelf = self else { return }
                
                let location = place.coordinate.getCLLocation()
                strongSelf.stationService.getNearestStations(location, radius: Constants.MapDefaults.stationsMinimunDistance).observeNext({ (stations) in
                    
                    var displayStations = stations
                    if let tapped = lastTappedMarker {
                        displayStations = stations.filter({ $0.location.googleString() != tapped.position.googleString() })
                    }

                    strongSelf.showLocationAndNearestStations(mapView, location: location, stations: displayStations)
                    
                }).disposeIn(strongSelf.disposeBag)
                
            }.disposeIn(disposeBag)
        
    }
    
    private func centerCameraOnMyLocation(mapView: GMSMapView) -> GMSCameraUpdate {
        if let location = mapView.myLocation {
            return self.centerCamera(mapView, onLocation: location)
        }
        return self.centerCamera(mapView, onLocation: Constants.MapDefaults.dublinCoords)
    }
    
    private func centerCamera(mapView: GMSMapView, onLocation location: CLLocation) -> GMSCameraUpdate {
        return GMSCameraUpdate.setTarget(location.coordinate, zoom: Constants.MapDefaults.zoom)
    }
    
    private func centerCameraOnPath(mapView: GMSMapView, path: GMSPath) -> GMSCameraUpdate {
        let navigationBarHeight = topLayoutGuide.length ?? 0
        return GMSCameraUpdate.fitBounds(GMSCoordinateBounds(path: path),
                                         withEdgeInsets: UIEdgeInsets(top: navigationBarHeight+Constants.MapDefaults.routePadding,
                                            left: Constants.MapDefaults.routePadding,
                                            bottom: Constants.MapDefaults.routePadding,
                                            right: Constants.MapDefaults.routePadding))
    }
    
}
