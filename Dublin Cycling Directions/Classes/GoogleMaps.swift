//
//  GoogleMaps.swift
//  Dublin Cycling Directions
//
//  Created by Adriano Goncalves on 05/06/2016.
//  Copyright © 2016 Adriano Goncalves. All rights reserved.
//

import Foundation
import GoogleMaps
import ReactiveKit

extension GMSMapView {
    
    var rDelegate: ProtocolProxy {
        return protocolProxyFor(GMSMapViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
    }
    
    var tappedMarker: Stream<GMSMarker?> {
        return rDelegate.streamFor(#selector(GMSMapViewDelegate.mapView(_:didTapMarker:)),
                                   map: { (mapView: GMSMapView, marker: GMSMarker) in marker })
    }
    
    var tappedMyLocation: Stream<Bool> {
        return rDelegate.streamFor(#selector(GMSMapViewDelegate.didTapMyLocationButtonForMapView(_:))) { (mapView: GMSMapView) in true }
    }
    
    var tappedSourceStations: Stream<GMSMarker?> {
        return tappedMarker.filter {
            guard let marker = $0 else { return false }
            return marker.isSourceStation
        }
    }

    var tappedDestinationStations: Stream<GMSMarker?> {
        return tappedMarker.filter {
            guard let marker = $0 else { return false }
            return !marker.isSourceStation
        }
    }

}

enum GMSAutocompleteViewControllerError<E: NSError>: ErrorType {
    case Error(E)
    
    func value() -> E {
        switch self {
        case .Error(let error):
            return error
        }
    }
}

extension GMSAutocompleteViewController {
    
    var rDelegate: ProtocolProxy {
        return protocolProxyFor(GMSAutocompleteViewControllerDelegate.self, setter: NSSelectorFromString("setDelegate:"))
    }
    
    var selectedPlace: Stream<GMSPlace> {
        return rDelegate.streamFor(#selector(GMSAutocompleteViewControllerDelegate.viewController(_:didAutocompleteWithPlace:))) {
            (controller: GMSAutocompleteViewController, place: GMSPlace) in place
        }
    }
    
    var error: Stream<GMSAutocompleteViewControllerError<NSError>> {
        return rDelegate.streamFor(#selector(GMSAutocompleteViewControllerDelegate.viewController(_:didFailAutocompleteWithError:))) {
            (controller: GMSAutocompleteViewController, error: NSError) in .Error(error)
        }
    }
    
    var cancelled: Stream<Bool> {
        return rDelegate.streamFor(#selector(GMSAutocompleteViewControllerDelegate.wasCancelled(_:))) { (
            controller: GMSAutocompleteViewController) in true
        }
    }
    
}

extension GMSMarker {

    var isSourceStation: Bool {
        get {
            if let userData = userData as? [String:AnyObject],
                keyValue = userData[Constants.Keys.isSourceStation] as? Bool
                where userData.keys.contains(Constants.Keys.isSourceStation) && userData[Constants.Keys.isSourceStation] is Bool {
                return keyValue
            }
            return false
        }
        set {
            if let userData = userData as? [String:AnyObject] {
                var data = userData
                data[Constants.Keys.isSourceStation] = newValue
                self.userData = data
            } else {
                self.userData = [Constants.Keys.isSourceStation:newValue]
            }
        }
    }
    
    static func newMarker(coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let startMarker = GMSMarker()
        startMarker.appearAnimation = kGMSMarkerAnimationPop
        startMarker.position = coordinate
        return startMarker
    }
    
    static func startMarker(coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let startMarker = GMSMarker.newMarker(coordinate)
        startMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        return startMarker
    }

    static func endMarker(coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let endMarker = GMSMarker.newMarker(coordinate)
        endMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        return endMarker
    }
    
    static func placeMarker(coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let placeMarker = GMSMarker.newMarker(coordinate)
        placeMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
        return placeMarker
    }

}
