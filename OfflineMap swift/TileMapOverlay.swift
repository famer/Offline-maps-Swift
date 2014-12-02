//
//  TileMapOverlay.swift
//  OfflineMap swift
//
//  Created by Тимур Татаршаов on 25.11.14.
//  Copyright (c) 2014 Timur Tatarshaov. All rights reserved.
//

import Foundation
import MapKit

class TileMapOverlay: NSObject, MKOverlay {
    
    var overlayCoordinates: CLLocationCoordinate2D
    var overlayBoundingMapRect: MKMapRect
    var bottomLeft: CLLocationCoordinate2D
    var topRight: CLLocationCoordinate2D
    var image: UIImage
    
    init (bottomLeft: CLLocationCoordinate2D, topRight: CLLocationCoordinate2D, image: UIImage) {
        self.bottomLeft = bottomLeft
        self.topRight = topRight
        self.image = image
        
        let middleLatitude = (bottomLeft.latitude + topRight.latitude ) / 2.0
        let middleLongitude = (bottomLeft.longitude + topRight.longitude ) / 2.0
        overlayCoordinates = CLLocationCoordinate2D(latitude: middleLatitude, longitude: middleLongitude)
        
        let upperLeft: MKMapPoint = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: topRight.latitude, longitude: bottomLeft.longitude));
        let lowerLeft: MKMapPoint = MKMapPointForCoordinate(bottomLeft);
        let upperRight: MKMapPoint = MKMapPointForCoordinate(topRight);
        
        overlayBoundingMapRect = MKMapRectMake(upperLeft.x, upperLeft.y, fabs(upperLeft.x - upperRight.x), fabs(upperLeft.y - lowerLeft.y))
        
    }
    
    var coordinate: CLLocationCoordinate2D {
        return self.overlayCoordinates
    }
    
    var boundingMapRect: MKMapRect {
        return self.overlayBoundingMapRect
    }
}