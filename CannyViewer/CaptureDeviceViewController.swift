//
//  CaptureDeviceViewController.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 24/03/2021.
//

import Cocoa
import AVFoundation

class CaptureDeviceViewController: NSViewController {
    var captureDevices: [AVCaptureDevice]!{
        didSet{
            update()
        }
    }
    private var captureDeviceController: CaptureDeviceController!
    
    @IBOutlet var deviceList: NSPopUpButton!
    @IBOutlet var formatList: NSPopUpButton!
    @IBOutlet var resolutionList: NSPopUpButton!
    @IBOutlet var frameRateSlider: NSSlider!
    @IBOutlet var frameRateLabel: NSSlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.captureDevices = []
        self.captureDeviceController = CaptureDeviceController()
    }
    
    func update(){
        if self.captureDevices.count == 0 {return}
        
        self.captureDeviceController.captureDevice = self.captureDevices[0]
        self.updateDeviceList()
    }
    
    func updateDeviceList(){
        self.deviceList.removeAllItems()
        
        let menu = NSMenu()
        for device in self.captureDevices{
            let menuItem = NSMenuItem()
            menuItem.title = device.localizedName
            menuItem.representedObject = device
            menuItem.action = #selector(self.deviceDidChange(menuItem:))
            menuItem.target = self
            menu.addItem(menuItem)
        }

        self.deviceList.menu = menu
        self.deviceList.selectItem(at: 0)
        self.deviceList.synchronizeTitleAndSelectedItem()
        self.deviceList.menu?.performActionForItem(at: 0)
    }
    
    @objc func deviceDidChange(menuItem: NSMenuItem){
        guard let device = menuItem.representedObject as? AVCaptureDevice else{return}
        
        self.captureDeviceController.captureDevice = device
        
        self.updateFormats()
    }
    
    func updateFormats(){
        self.formatList.removeAllItems()
        
        let menu = NSMenu()
        for format in self.captureDeviceController.mediaTypes(){
            let menuItem = NSMenuItem()
            menuItem.title = format.description
            menuItem.representedObject = format
            menuItem.action = #selector(self.formatDidChange(menuItem:))
            menuItem.target = self
            menu.addItem(menuItem)
        }
        
        self.formatList.menu = menu
        
        if let index = self.captureDeviceController.mediaTypes().firstIndex(of: self.captureDeviceController.captureDevice.activeFormat.formatDescription.mediaSubType){
            self.formatList.selectItem(at: index)
            self.formatList.synchronizeTitleAndSelectedItem()
            self.formatList.menu?.performActionForItem(at: index)
        }
    }
    
    @objc func formatDidChange(menuItem: NSMenuItem){
        
    }
}
