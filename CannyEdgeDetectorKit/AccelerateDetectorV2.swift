//
//  AccelerateDetectorV2.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 13/03/2021.
//

import Foundation
import Accelerate
import AVFoundation

public class AccelerateDetectorV2: DetectorStrategy{
    public var outputFormat: vImage_CGImageFormat
    let boxFilter: BoxFilter
    
    public init(){
        self.outputFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
        self.boxFilter = BoxFilter()
    }
    
    public func detect(_ imageBuffer: CVPixelBuffer) throws -> CGImage? {
        guard let lumaBuffer = self.getPlaneImageBuffer(imageBuffer, planeIndex: 0) else{
            return nil
        }
        
        let blurredBuffer = self.boxFilter.filter(input: lumaBuffer)
        
        return try? blurredBuffer.image.createCGImage(format: self.outputFormat)
    }
    
    func getPlaneImageBuffer(_ imageBuffer: CVPixelBuffer, planeIndex: Int) -> VImageBufferWrapper?{
        assert(planeIndex < CVPixelBufferGetPlaneCount(imageBuffer))
        
        let planeWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex)
        let planeHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex)
        let planeBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, planeIndex)
        let byteSize = planeBytesPerRow * planeHeight
        
        guard let planePointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {return nil}
        let planeCopyPointer = UnsafeMutableRawPointer.allocate(byteCount: byteSize, alignment: 64)
        planeCopyPointer.copyMemory(from: planePointer, byteCount: byteSize)
        return VImageBufferWrapper(image: vImage_Buffer(data: planeCopyPointer, height: UInt(planeHeight), width: UInt(planeWidth), rowBytes: planeBytesPerRow))
    }
}
