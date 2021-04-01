//
//  BoxFilterStep.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation
import Accelerate

class BoxFilterStep: PipelineStep{
    override func execute() throws {
        try self.checkNumberOfInputs(expected: 1)
        
        let inputBuffer = try self.getInputData(index: 0, type: VImageBufferWrapper.self)
        let outputBuffer = try VImageBufferWrapper(image: vImage_Buffer(width: Int(inputBuffer.image.width), height: Int(inputBuffer.image.height), bitsPerPixel: 8))
        
        let error = vImageBoxConvolve_Planar8(&inputBuffer.image, &outputBuffer.image, nil, 0, 0, 3, 3, 0, vImage_Flags(kvImageEdgeExtend))
        
        if error != kvImageNoError{
            throw PipelineError.genericError("BoxFilterStep cannot apply the box filter.")
        }
        
        self.outputs.removeAll()
        self.outputs.append(.vimageBuffer(outputBuffer))
        /*
        var inputBuffer: VImageBufferWrapper
        var outputBuffer: VImageBufferWrapper
        
        if self.inputs.count == 1{
            switch(self.inputs[0]){
            case .vimageBuffer(let buffer):
                inputBuffer = buffer
            default:
                throw PipelineError.invalidInput("BoxFilterStep requires one input of type vImage_Buffer.")
            }
        }else{
            throw PipelineError.invalidInput("BoxFilterStep requires one input of type vImage_Buffer.")
        }
        
        if self.outputs.count == 0{
            guard let buffer = try? vImage_Buffer(width: Int(inputBuffer.image.width), height: Int(inputBuffer.image.height), bitsPerPixel: 8) else{
                throw PipelineError.creationError("GrayscaleConverterStep cannot create the output image buffer.")
            }
            outputBuffer = VImageBufferWrapper(image: buffer)
        }else{
            switch (self.outputs[0]) {
            case .vimageBuffer(let buffer):
                outputBuffer = buffer
            default:
                throw PipelineError.genericError("GrayscaleConverterStep expects one output of type vImage_Buffer, but instead has found a different number of outputs or of an invalid type(s).")
            }
        }
        
        if kvImageNoError != vImageBoxConvolve_Planar8(&inputBuffer.image, &outputBuffer.image, nil, 0, 0, 5, 5, 0, vImage_Flags(kvImageEdgeExtend)){
            throw PipelineError.genericError("BoxFilterStep cannot apply the box filter.")
        }
        
        if self.outputs.count == 0{
            self.outputs.append(.vimageBuffer(outputBuffer))
        }else{
            self.outputs[0] = .vimageBuffer(outputBuffer)
        }
 */
    }
}
