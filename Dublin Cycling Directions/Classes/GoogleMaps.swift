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
        return rDelegate.streamFor(#selector(GMSMapViewDelegate.mapView(_:didTapMarker:))) { (mapView: GMSMapView, marker: GMSMarker) in marker }
    }
    
    var tappedMyLocation: Stream<Bool> {
        return rDelegate.streamFor(#selector(GMSMapViewDelegate.didTapMyLocationButtonForMapView(_:))) { (mapView: GMSMapView) in true }
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
