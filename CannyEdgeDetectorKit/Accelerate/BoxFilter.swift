//
//  BoxFilter.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 13/03/2021.
//

import Foundation
import Accelerate

class BoxFilter{
    let output: VImageBufferWrapper
    let temporaryBuffer: TemporaryBuffer
    
    init(){
        self.output = VImageBufferWrapper()
        self.temporaryBuffer = TemporaryBuffer()
    }
    
    func filter(input: VImageBufferWrapper) -> VImageBufferWrapper{
        self.output.allocIfNeeded(image: input.image, bitsPerPixel: 8)
        
        let temporarySize = vImageBoxConvolve_Planar8(&input.image, &self.output.image, nil, 0, 0, 5, 5, 0, vImage_Flags(kvImageEdgeExtend | kvImageGetTempBufferSize | kvImagePrintDiagnosticsToConsole))
        
        self.temporaryBuffer.reallocIfNeeded(newSize: temporarySize)
        
        vImageBoxConvolve_Planar8(&input.image, &self.output.image, self.temporaryBuffer.buffer, 0, 0, 5, 5, 0, vImage_Flags(kvImageEdgeExtend | kvImagePrintDiagnosticsToConsole))
        
        return self.output
    }
}
