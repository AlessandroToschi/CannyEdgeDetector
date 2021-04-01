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
    let gradient: Gradient
    let nonMaxSuppression: NonMaxSuppression
    let threshold: Threshold
    
    public init(){
        self.outputFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
        self.boxFilter = BoxFilter()
        self.gradient = Gradient()
        self.nonMaxSuppression = NonMaxSuppression()
        self.threshold = Threshold()
    }
    
    public func detect(_ imageBuffer: CVPixelBuffer) throws -> CGImage? {
        guard let lumaBuffer = self.getPlaneImageBuffer(imageBuffer, planeIndex: 0) else{
            return nil
        }
        let blurredBuffer = self.boxFilter.filter(input: lumaBuffer)
        var (magnitude, theta) = self.gradient.compute(input: blurredBuffer)
        magnitude = self.nonMaxSuppression.compute(magnitude: magnitude, theta: theta)
        let output = self.threshold.compute(input: magnitude)
        
        return try? output.image.createCGImage(format: self.outputFormat)
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
    
    func dump(image: VImageBufferWrapper, fileName: String){
        let size = image.image.rowBytes * Int(image.image.height)
        let pointer = UnsafeRawPointer(image.image.data)!
        let data = Data(bytes: pointer, count: size)
        try! data.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/\(fileName)"))
    }
    
    func dump(buffer: [Float], fileName: String){
        buffer.withUnsafeBytes{pointer in
            let data = Data(bytes: pointer.baseAddress!, count: pointer.count)
            try! data.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/\(fileName)"))
        }
    }
}
