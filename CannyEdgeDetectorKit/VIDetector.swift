//
//  VIDetector.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 15/02/2021.
//

import Foundation
import Accelerate

public class VIDetector: Detector{
    public func setup() -> Bool {
        return false
    }
    
    public var image: CGImage
    
    public init(image: CGImage){
        self.image = image
    }
    
    public func compute(image: CGImage) -> CGImage? {
        
        guard var grayImage = toGrayscale(),
              var noiseFreeImage = noiseReduction(sourceBuffer: &grayImage.buffer, format: grayImage.format) else{
            return nil
        }
        let resultImage = try? noiseFreeImage.buffer.createCGImage(format: noiseFreeImage.format)
        noiseFreeImage.buffer.free()
        return resultImage
    }
    
    func toGrayscale() -> (buffer: vImage_Buffer, format: vImage_CGImageFormat)?{
        guard var sourceImageFormat = vImage_CGImageFormat(cgImage: self.image),
              var destinationImageFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
              ),
              var sourceBuffer = try? vImage_Buffer(cgImage: self.image, format: sourceImageFormat),
              var destinationBuffer = try? vImage_Buffer(
                width: self.image.width,
                height: self.image.height,
                bitsPerPixel: destinationImageFormat.bitsPerPixel
              )else{
            return nil
        }
        let imageConverter = vImageConverter_CreateWithCGImageFormat(
            &sourceImageFormat,
            &destinationImageFormat,
            nil,
            vImage_Flags(kvImagePrintDiagnosticsToConsole),
            nil
        ).takeRetainedValue()
        
        let bytesRequired = vImageConvert_AnyToAny(imageConverter, &sourceBuffer, &destinationBuffer, nil, vImage_Flags(kvImageGetTempBufferSize))
        print(bytesRequired)
        
        vImageConvert_AnyToAny(
            imageConverter,
            &sourceBuffer,
            &destinationBuffer,
            nil,
            vImage_Flags(kvImagePrintDiagnosticsToConsole)
        )

        sourceBuffer.free()
        
        return (destinationBuffer, destinationImageFormat)
    }
    
    func noiseReduction( sourceBuffer: inout vImage_Buffer, format: vImage_CGImageFormat) -> (buffer: vImage_Buffer, format: vImage_CGImageFormat)?{
        guard var destinationBuffer = try? vImage_Buffer(width: self.image.width, height: self.image.height, bitsPerPixel: format.bitsPerPixel) else{
            return nil
        }
        vImageBoxConvolve_Planar8(
            &sourceBuffer,
            &destinationBuffer,
            nil,
            0,
            0,
            5,
            5,
            0,
            vImage_Flags(kvImageEdgeExtend)
        )
        sourceBuffer.free()
        return (destinationBuffer, format)
    }
}
