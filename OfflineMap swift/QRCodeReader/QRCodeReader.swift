/*
* QRCodeReader.swift
*
* Copyright 2014-present Yannick Loriot.
* http://yannickloriot.com
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/

import UIKit
import AVFoundation
import MediaPlayer

class QRCodeReader: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var catchedInfo: String?
  private var cameraView: ReaderView = ReaderView()
  private var cancelButton: UIButton = UIButton()
    private var captureButton: UIButton = UIButton(frame: CGRectMake(200, 200, 45, 45))
  private var switchCameraButton: SwitchCameraButton?
    let stillImageOutput = AVCaptureStillImageOutput()
  
  private var defaultDevice: AVCaptureDevice? = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
  private var frontDevice: AVCaptureDevice?   = {
    for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
      if let _device = device as? AVCaptureDevice {
        if _device.position == AVCaptureDevicePosition.Front {
          return _device
        }
      }
    }
  
    return nil
    }()
  private lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
    if let _defaultDevice = self.defaultDevice {
      return AVCaptureDeviceInput(device: _defaultDevice, error: nil)
    }
    
    return nil
    }()
  private lazy var frontDeviceInput: AVCaptureDeviceInput?  = {
    if let _frontDevice = self.frontDevice {
      return AVCaptureDeviceInput(device: _frontDevice, error: nil)
    }
    
    return nil
    }()
  private var metadataOutput: AVCaptureMetadataOutput       = AVCaptureMetadataOutput()
  private var session: AVCaptureSession                     = AVCaptureSession()
  private lazy var previewLayer: AVCaptureVideoPreviewLayer = { return AVCaptureVideoPreviewLayer(session: self.session) }()
  
  weak var delegate: QRCodeReaderDelegate?
  var completionBlock: ((String?) -> ())?
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  required init(cancelButtonTitle: String) {
    super.init()
    
    configureDefaultComponents()
    setupUIComponentsWithCancelButtonTitle(cancelButtonTitle)
    setupAutoLayoutConstraints()
    
    view.backgroundColor = UIColor.blackColor()
    
    cameraView.layer.insertSublayer(previewLayer, atIndex: 0)
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    startScanning()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationDidChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
  }
  
  override func viewWillDisappear(animated: Bool) {
    stopScanning()
    
    super.viewWillDisappear(animated)
  }
  
  override func viewWillLayoutSubviews() {
    previewLayer.frame = view.bounds
  }
  
  // MARK: - Managing the Orientation
  
  func orientationDidChanged(notification: NSNotification) {
    cameraView.setNeedsDisplay()
    
    if previewLayer.connection != nil {
      var interfaceOrientation: UIInterfaceOrientation = .Portrait
      
      switch (UIDevice.currentDevice().orientation) {
      case .LandscapeLeft:
        interfaceOrientation = .LandscapeRight
      case .LandscapeRight:
        interfaceOrientation = .LandscapeLeft
      case .PortraitUpsideDown:
        interfaceOrientation = .PortraitUpsideDown
      default:
        interfaceOrientation = .Portrait
      }
      
      previewLayer.connection.videoOrientation = QRCodeReader.videoOrientationFromInterfaceOrientation(interfaceOrientation)
    }
  }
  
  class func videoOrientationFromInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
    switch (interfaceOrientation) {
    case .LandscapeLeft:
      return .LandscapeLeft
    case .LandscapeRight:
      return .LandscapeRight
    case .Portrait:
      return .Portrait
    default:
      return .PortraitUpsideDown
    }
  }
  
  // MARK: - Initializing the AV Components
  
  private func setupUIComponentsWithCancelButtonTitle(cancelButtonTitle: String) {
    cameraView.clipsToBounds = true
    cameraView.setTranslatesAutoresizingMaskIntoConstraints(false)
    view.addSubview(cameraView)
    
    if let _frontDevice = frontDevice {
      let newSwitchCameraButton = SwitchCameraButton()
      newSwitchCameraButton.setTranslatesAutoresizingMaskIntoConstraints(false)
      newSwitchCameraButton.addTarget(self, action: "switchCameraAction:", forControlEvents: .TouchUpInside)
      view.addSubview(newSwitchCameraButton)
      
      switchCameraButton = newSwitchCameraButton
    }
    
    cancelButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    cancelButton.setTitle(cancelButtonTitle, forState: .Normal)
    cancelButton.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
    cancelButton.addTarget(self, action: "cancelAction:", forControlEvents: .TouchUpInside)
    
    captureButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    captureButton.setTitle("Capture", forState: .Normal)
    captureButton.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
    captureButton.addTarget(self, action: "captureAction:", forControlEvents: .TouchUpInside)
    captureButton.frame = CGRect(x: 100, y: 200, width: 100, height: 45)
    view.addSubview(cancelButton)
    view.addSubview(captureButton)
  }
  
  private func setupAutoLayoutConstraints() {
    let views: [NSObject: AnyObject] = ["cameraView": cameraView, "cancelButton": cancelButton, "captureButton": captureButton]
    
    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[cameraView][cancelButton(40)][captureButton(40)]|", options: .allZeros, metrics: nil, views: views))
    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cameraView]|", options: .allZeros, metrics: nil, views: views))
    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[cancelButton]-|", options: .allZeros, metrics: nil, views: views))
    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[captureButton]-|", options: .allZeros, metrics: nil, views: views))
    
    if let _switchCameraButton = switchCameraButton {
      let switchViews: [NSObject: AnyObject] = ["switchCameraButton": _switchCameraButton]
      
      view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[switchCameraButton(50)]", options: .allZeros, metrics: nil, views: switchViews))
      view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[switchCameraButton(70)]|", options: .allZeros, metrics: nil, views: switchViews))
    }
  }
  
  private func configureDefaultComponents() {
    session.addOutput(metadataOutput)
    session.addOutput(stillImageOutput)
    
    if let _defaultDeviceInput = defaultDeviceInput {
      session.addInput(defaultDeviceInput)
    }
    
    metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    if let _availableMetadataObjectTypes = metadataOutput.availableMetadataObjectTypes as? [String] {
      if _availableMetadataObjectTypes.filter({ $0 == AVMetadataObjectTypeQRCode }).count > 0 {
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
      }
    }
    previewLayer.videoGravity          = AVLayerVideoGravityResizeAspectFill

    if previewLayer.connection != nil && previewLayer.connection.supportsVideoOrientation {
      previewLayer.connection.videoOrientation = QRCodeReader.videoOrientationFromInterfaceOrientation(interfaceOrientation)
    }
  }
  
  private func switchDeviceInput() {
    if let _frontDeviceInput = frontDeviceInput {
      session.beginConfiguration()
      
      if let _currentInput = session.inputs.first as? AVCaptureDeviceInput {
        session.removeInput(_currentInput)
        
        let newDeviceInput = (_currentInput.device.position == .Front) ? defaultDeviceInput : _frontDeviceInput
        session.addInput(newDeviceInput)
      }
      
      session.commitConfiguration()
    }
  }
  
  // MARK: - Controlling Reader
  
  private func startScanning() {
    if !session.running {
      session.startRunning()
    }
  }
  
  private func stopScanning() {
    if session.running {
      session.stopRunning()
    }
  }
  
  // MARK: - Catching Button Events
  
  func cancelAction(button: UIButton) {
    stopScanning()
    
    if let _completionBlock = completionBlock {
      _completionBlock(nil)
    }
    
    delegate?.readerDidCancel(self)
  }
  
  func switchCameraAction(button: SwitchCameraButton) {
    switchDeviceInput()
  }
  
  // MARK: - AVCaptureMetadataOutputObjects Delegate Methods
  
    func captureAction(button: UIButton) {
        if (self.catchedInfo != nil) {
            let videoConnection:AVCaptureConnection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
            videoConnection.videoOrientation = QRCodeReader.videoOrientationFromInterfaceOrientation(interfaceOrientation) //.setVideoOrientation(self.interfaceOrientation as AVCaptureVideoOrientation)
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
                let imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                let image: UIImage = UIImage(data:imageData)!
                
                let iView: UIImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 445.0, height: 445.0))
                iView.image = image
                self.view.addSubview(iView)
                //println(image)
                self.stopScanning()
                
                
                if let _completionBlock = self.completionBlock {
                    _completionBlock(self.catchedInfo)
                }
                
                self.delegate?.reader(self, didScanResult: self.catchedInfo!, image: image)
                
                
            })
            
        }
    }
    
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    if self.catchedInfo != nil {
        return
    }
    for current in metadataObjects {
      if let _readableCodeObject = current as? AVMetadataMachineReadableCodeObject {
        if _readableCodeObject.type == AVMetadataObjectTypeQRCode {
            self.catchedInfo = _readableCodeObject.stringValue
            AudioServicesPlaySystemSound(1352)
           /*
          stopScanning()
          
          let scannedResult: String = _readableCodeObject.stringValue
          
          if let _completionBlock = completionBlock {
            _completionBlock(scannedResult)
          }
          
          delegate?.reader(self, didScanResult: scannedResult)
            */
        }
      }
    }
  }
}


protocol QRCodeReaderDelegate: class {
    func reader(reader: QRCodeReader, didScanResult result: String, image: UIImage)
  func readerDidCancel(reader: QRCodeReader)
}