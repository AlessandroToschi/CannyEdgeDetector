//
//  CannyEdgeDetector.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 13/03/2021.
//

import Foundation
import AVFoundation
import Accelerate

public class CannyEdgeDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    let strategy: DetectorStrategy
    let outputFormat: vImage_CGImageFormat
    public weak var delegate: CannyEdgeDetectorDelegate?
    
    public init(strategy: DetectorStrategy){
        self.strategy = strategy
        self.outputFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
    }
    
    @objc public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let startTime = DispatchTime.now()
        guard let imageBuffer = sampleBuffer.imageBuffer else {return}
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer{
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            let endTime = DispatchTime.now()
            let elapsed = (endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            print("Elapsed: \(elapsed) ms")
        }
        
        assert(CVPixelBufferIsPlanar(imageBuffer))
        assert(CVPixelBufferGetPlaneCount(imageBuffer) >= 2)
        
        guard let outputImage = try? self.strategy.detect(imageBuffer) else{
            print("is nil")
            return
            
        }
        
        
        self.delegate?.ouputHandler(image: outputImage)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("dropping")
    }

}
