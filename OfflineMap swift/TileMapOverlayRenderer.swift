//
//  TileMapOverlayRenderer.swift
//  OfflineMap swift
//
//  Created by Тимур Татаршаов on 25.11.14.
//  Copyright (c) 2014 Timur Tatarshaov. All rights reserved.
//

import Foundation
import MapKit

class TileMapOverlayRenderer: MKOverlayRenderer{
    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext!) {
        
        let image = (self.overlay as TileMapOverlay).image
        
        /*
        var imageReference: CGImageRef = image!.CGImage;
        var theMapRect: MKMapRect  = self.overlay.boundingMapRect
        var theRect: CGRect           = self.rectForMapRect(theMapRect)
        var clipRect: CGRect   = self.rectForMapRect(mapRect)
        
        CGContextAddRect(context, clipRect);
        CGContextClip(context);
        CGContextDrawImage(context, theRect, imageReference);
        */
        
        let theMapRect: MKMapRect = self.overlay.boundingMapRect;
        let theRect: CGRect = self.rectForMapRect(theMapRect);
        
        UIGraphicsPushContext(context);
        image.drawInRect(theRect, blendMode: kCGBlendModeNormal, alpha: 1.0)
        UIGraphicsPopContext();
        
      
    }
}