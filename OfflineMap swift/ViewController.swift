//
//  ViewController.swift
//  OfflineMap swift
//
//  Created by Тимур Татаршаов on 25.11.14.
//  Copyright (c) 2014 Timur Tatarshaov. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, QRCodeReaderDelegate, ImageCropViewControllerDelegate {
    lazy var reader: QRCodeReader = QRCodeReader(cancelButtonTitle: "Cancel")
    
    @IBOutlet weak var mapKitView: MKMapView!
    var bottom = CLLocationCoordinate2D(latitude: 50.080521, longitude: 14.408675)
    var top = CLLocationCoordinate2D(latitude: 50.090476, longitude: 14.437665)
    //let current = CLLocationCoordinate2D(latitude: 50.085521, longitude: 14.428675)
    let locationManager = CLLocationManager()
    var scanResult: String?
    var overlayImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        
        //mapKitView.userTrackingMode = MKUserTrackingMode.FollowWithHeading
        //mapKitView.rotateEnabled = false
        mapKitView.delegate = self
        mapKitView.showsUserLocation = true
        
        //let image = UIImage(named: "map.png")
        //let overlay = TileMapOverlay(bottomLeft: bottom, topRight: top, image: image!)
        
        //mapKitView.addOverlay(overlay)
        
        
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let mapOverlay = TileMapOverlayRenderer(overlay: overlay)
        return mapOverlay
    }
    
    @IBAction func scanAction(sender: AnyObject) {
        reader.modalPresentationStyle = .FormSheet
        reader.delegate               = self
        
       
        
        presentViewController(reader, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(reader: QRCodeReader, didScanResult result: String, image: UIImage) {
        self.dismissViewControllerAnimated(true, completion: nil)
       
        scanResult = result
        overlayImage = image
        cropImage(image)
        
        
        
    }
    
    func readerDidCancel(reader: QRCodeReader) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func cropImage(image: UIImage) {
        let controller: ImageCropViewController = ImageCropViewController(image: image);
        controller.delegate = self;
        controller.blurredBackground = true;
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func imageCropViewControllerDidCancel(controller: UIViewController!) {
        createOverlay()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageCropViewControllerDidFinish(controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        overlayImage = croppedImage
        createOverlay()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
  
    func createOverlay() {
        let coordinates = scanResult!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        if coordinates.count == 2 {
            let _bottom = coordinates[0].componentsSeparatedByString(" ")
            let _top = coordinates[1].componentsSeparatedByString(" ")
            var bottom = CLLocationCoordinate2D(latitude: (_bottom[0] as NSString).doubleValue, longitude: (_bottom[1] as NSString).doubleValue)
            var top = CLLocationCoordinate2D(latitude: (_top[0] as NSString).doubleValue, longitude: (_top[1] as NSString).doubleValue)
            
            let overlay = TileMapOverlay(bottomLeft: bottom, topRight: top, image: overlayImage!)
            
            mapKitView.addOverlay(overlay)
        } else {
            println(coordinates.count)
        }
    }


}

