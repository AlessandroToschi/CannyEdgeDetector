//
//  GrayscaleConverter.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 28/02/2021.
//

import Foundation
import Accelerate

class GrayscaleConverter{
    var outputBuffer: VImageBufferWrapper!
    let colorSpace: CGColorSpace
    let temporaryBuffer: TemporaryBuffer
    
    init(){
        self.outputBuffer = nil
        self.colorSpace = CGColorSpaceCreateDeviceGray()
        self.temporaryBuffer = TemporaryBuffer()
    }
    
    func execute(image: CGImage) throws -> VImageBufferWrapper{
        let inputBuffer = try VImageBufferWrapper(image: vImage_Buffer(cgImage: image))
        
        if  self.outputBuffer == nil ||
            self.outputBuffer.image.width != inputBuffer.image.width ||
            self.outputBuffer.image.height != inputBuffer.image.height{
            self.outputBuffer = try VImageBufferWrapper(image: vImage_Buffer(width: Int(inputBuffer.image.width), height: Int(inputBuffer.image.height), bitsPerPixel: 8))
        }
        
        guard let inputFormat = vImage_CGImageFormat(cgImage: image),
              let outputFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: self.colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)) else{
            throw PipelineError.genericError("nnnnnn")
        }
        
        let converter = try vImageConverter.make(sourceFormat: inputFormat, destinationFormat: outputFormat)
        let temporaryBytes = vImageConvert_AnyToAny(converter, &inputBuffer.image, &self.outputBuffer.image, nil, vImage_Flags(kvImageGetTempBufferSize))
        
        self.temporaryBuffer.reallocIfNeeded(newSize: temporaryBytes)
        vImageConvert_AnyToAny(converter, &inputBuffer.image, &outputBuffer.image, self.temporaryBuffer.buffer, vImage_Flags(kvImageNoFlags))
        
        return self.outputBuffer
    }
}
