//
//  LiveViewController.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 28/02/2021.
//

import Cocoa
import AVFoundation
import CannyEdgeDetectorKit

class LiveViewController: NSViewController, CannyEdgeDetectorDelegate {
    func ouputHandler(image: CGImage) {
        DispatchQueue.main.async {
            self.liveView.image = image
        }
    }
    
    @IBOutlet var deviceList: NSPopUpButton!
    @IBOutlet var resolutionList: NSPopUpButton!
    @IBOutlet var frameRateSlider: NSSlider!
    @IBOutlet var frameRateLabel: NSTextField!
    @IBOutlet var startStopSessionButton: NSButton!
    @IBOutlet var liveView: LiveView!
    
    let inputPixelFormat = CMFormatDescription.MediaSubType(rawValue: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
    let outputPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    
    var captureSession: AVCaptureSession!
    var formats: [AVCaptureDevice.Format]!
    var controlsToToggle: [NSControl]!
    var timerConsumser: TimerConsumer!
    var strategy: DetectorStrategy!
    var cannyEdgeDetector: CannyEdgeDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(inputPixelFormat)
        print(outputPixelFormat)
        self.timerConsumser = TimerConsumer()
        self.timerConsumser.liveView = self.liveView
        print(self.liveView.frame)
        
        self.strategy = MetalDetector()
        self.cannyEdgeDetector = CannyEdgeDetector(strategy: self.strategy)
        self.cannyEdgeDetector.delegate = self
        
        self.discoverAvailableDevices()
        self.checkForAutorization()
        
        self.controlsToToggle = [
            self.deviceList,
            self.resolutionList,
            self.frameRateSlider
        ]
        
        
    }
    
    func setupCaptureSession(){
        let selectedDevice = self.deviceList.selectedItem?.representedObject! as! AVCaptureDevice
        try! selectedDevice.lockForConfiguration()
        self.setupCaptureDevice(device: selectedDevice)
        
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        defer{
            self.captureSession.commitConfiguration()
            
        }
        guard let deviceInput = try? AVCaptureDeviceInput(device: selectedDevice),
              self.captureSession.canAddInput(deviceInput) else{
            fatalError("Cannot start the session")
        }
        
        self.captureSession.addInput(deviceInput)

        let outputDevice = AVCaptureVideoDataOutput()
        outputDevice.alwaysDiscardsLateVideoFrames = false
        outputDevice.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): self.outputPixelFormat]
        let queue = DispatchQueue(label: "aa")
        outputDevice.setSampleBufferDelegate(self.cannyEdgeDetector, queue: queue)
        
        if self.captureSession.canAddOutput(outputDevice){
            self.captureSession.addOutput(outputDevice)
        }
        
        self.strategy.prepare(width: Int(selectedDevice.activeFormat.formatDescription.dimensions.width), height: Int(selectedDevice.activeFormat.formatDescription.dimensions.height))
    }
    
    func checkForAutorization(){
        switch(AVCaptureDevice.authorizationStatus(for: AVMediaType.video)){
        case .authorized:
            //self.setupCaptureSession()
            break
        case .denied, .restricted:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video){
                granted in
                if granted{
                    //self.setupCaptureSession()
                }
            }
        @unknown default:
            return
        }
    }
    
    func discoverAvailableDevices(){
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        self.deviceList.autoenablesItems = false
        self.deviceList.removeAllItems()
        
        let menu = NSMenu()
        for device in discoverySession.devices{
            let menuItem = NSMenuItem()
            menuItem.title = device.localizedName
            menuItem.representedObject = device
            menuItem.action = #selector(self.deviceChange(menuItem:))
            menuItem.target = self
            menu.addItem(menuItem)
        }

        self.deviceList.menu = menu
        self.deviceList.selectItem(at: 0)
        self.deviceList.synchronizeTitleAndSelectedItem()
        self.deviceList.menu?.performActionForItem(at: 0)
    }
    
    @objc func deviceChange(menuItem: NSMenuItem){
        guard let selectedDevice = menuItem.representedObject as? AVCaptureDevice,
              let frameRateRange = selectedDevice.activeFormat.videoSupportedFrameRateRanges.first else{
            return
        }
        
        self.formats = selectedDevice.formats.filter{$0.formatDescription.mediaSubType == self.inputPixelFormat}
        let resolutions = formats.map{$0.formatDescription.dimensions}.sorted{x, y in
            (x.height * x.width) < (y.height * y.width)
        }
        let currentMinFrameRate = Int64(selectedDevice.activeVideoMinFrameDuration.timescale) / selectedDevice.activeVideoMinFrameDuration.value
        
        self.setResolutions(resolutions: resolutions, current: selectedDevice.activeFormat.formatDescription.dimensions)
        self.setFrameRate(frameRateRange: frameRateRange, current: Float64(currentMinFrameRate))
    }
    
    func setResolutions(resolutions: [CMVideoDimensions], current: CMVideoDimensions){
        guard let currentResolutionIndex = resolutions.firstIndex(of: current) else{
            fatalError("Cannot find the current resolution: \(current) in \(resolutions)")
        }
        self.resolutionList.autoenablesItems = false
        self.resolutionList.removeAllItems()
        
        let menu = NSMenu()
        for resolution in resolutions{
            let menuItem = NSMenuItem()
            menuItem.title = "\(resolution.width)x\(resolution.height)"
            menuItem.representedObject = resolution
            menu.addItem(menuItem)
        }
        
        self.resolutionList.menu = menu
        self.resolutionList.selectItem(at: currentResolutionIndex)
        self.deviceList.synchronizeTitleAndSelectedItem()
    }
    
    func setFrameRate(frameRateRange: AVFrameRateRange, current: Float64){
        self.frameRateSlider.action = #selector(self.frameRateSliderChange)
        self.frameRateSlider.allowsTickMarkValuesOnly = true
        self.frameRateSlider.numberOfTickMarks = Int(frameRateRange.maxFrameRate - frameRateRange.minFrameRate) + 1
        self.frameRateSlider.minValue = frameRateRange.minFrameRate
        self.frameRateSlider.maxValue = frameRateRange.maxFrameRate
        self.frameRateSlider.altIncrementValue = 1.0
        self.frameRateSlider.doubleValue = current
        self.frameRateSlider.target = self
        self.frameRateSlider.performClick(nil)
    }
    
    @objc func frameRateSliderChange(){
        self.frameRateLabel.stringValue = "FPS: \(self.frameRateSlider.integerValue)"
    }
    
    @objc func popupChange(popUpButton: NSPopUpButton){
        print("oooo")
    }
    
    @IBAction func startStopSession(button: NSButton!){
        if button.title == "Start"{
            button.title = "Stop"
            self.setupCaptureSession()
            self.captureSession.startRunning()
            print(captureSession.isRunning)
        }else{
            button.title = "Start"
            self.captureSession.stopRunning()
        }
        
        for control in self.controlsToToggle{
            control.isEnabled = !control.isEnabled
        }
    }
    
    func setupCaptureDevice(device: AVCaptureDevice){
        guard let resolution = self.resolutionList.selectedItem?.representedObject as? CMVideoDimensions,
              let format = self.formats.first(where: {
                $0.formatDescription.dimensions == resolution
              }) else{
            fatalError("Cannot retrieve the resolution from the list.")
        }
        let framerate = CMTime(value: 1, timescale: self.frameRateSlider.intValue)
        device.activeFormat = format
        device.activeVideoMinFrameDuration = framerate
        device.activeVideoMaxFrameDuration = framerate
    }
}
