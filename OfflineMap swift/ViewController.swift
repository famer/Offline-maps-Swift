//
//  ViewController.swift
//  OfflineMap swift
//
//  Created by Тимур Татаршаов on 25.11.14.
//  Copyright (c) 2014 Timur Tatarshaov. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, QRCodeReaderDelegate {
    lazy var reader: QRCodeReader = QRCodeReader(cancelButtonTitle: "Cancel")
    
    @IBOutlet weak var mapKitView: MKMapView!
    let bottom = CLLocationCoordinate2D(latitude: 50.080521, longitude: 14.408675)
    let top = CLLocationCoordinate2D(latitude: 50.090476, longitude: 14.437665)
    //let current = CLLocationCoordinate2D(latitude: 50.085521, longitude: 14.428675)
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        
        //mapKitView.userTrackingMode = MKUserTrackingMode.FollowWithHeading
        //mapKitView.rotateEnabled = false
        mapKitView.delegate = self
        mapKitView.showsUserLocation = true
        
        let image = UIImage(named: "map.png")
        let overlay = TileMapOverlay(bottomLeft: bottom, topRight: top, image: image!)
        
        //mapKitView.addOverlay(overlay)
        
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let mapOverlay = TileMapOverlayRenderer(overlay: overlay)
        return mapOverlay
    }
    
    @IBAction func scanAction(sender: AnyObject) {
        reader.modalPresentationStyle = .FormSheet
        reader.delegate               = self
        
        reader.completionBlock = { (result: String?) in
            println(result)
        }
        
        presentViewController(reader, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(reader: QRCodeReader, didScanResult result: String, image: UIImage) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let overlay = TileMapOverlay(bottomLeft: bottom, topRight: top, image: image)
        
        mapKitView.addOverlay(overlay)
    }
    
    func readerDidCancel(reader: QRCodeReader) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

