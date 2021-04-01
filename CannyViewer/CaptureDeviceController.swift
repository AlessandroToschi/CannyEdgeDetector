//
//  CaptureDeviceController.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 24/03/2021.
//

import Foundation
import AVFoundation

class CaptureDeviceController{
    var captureDevice: AVCaptureDevice!
    
    func mediaTypes() -> [CMFormatDescription.MediaSubType]{
        return self.captureDevice.formats.map{
            $0.formatDescription.mediaSubType
        }
    }
    
    func resolutions(mediaSubType: CMFormatDescription.MediaSubType) -> [CMVideoDimensions]{
        return self.captureDevice.formats.filter{
            $0.formatDescription.mediaSubType == mediaSubType
        }.map{
            $0.formatDescription.dimensions
        }
    }
    
    func frameRates(mediaSubType: CMFormatDescription.MediaSubType, resolution: CMVideoDimensions) -> [AVFrameRateRange]{
        return self.captureDevice.formats.filter{
            $0.formatDescription.mediaSubType == mediaSubType &&
            $0.formatDescription.dimensions == resolution
        }.first?.videoSupportedFrameRateRanges ?? []
    }
}
