//
//  GrayscaleConverterStep.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation
import Accelerate

final class GrayscaleConverterStep: PipelineStep{
    override func execute() throws {
        try self.checkNumberOfInputs(expected: 1)
        
        let inputImage = try self.getInputData(index: 0, type: CGImage.self)
        let inputBuffer = try VImageBufferWrapper(image: vImage_Buffer(cgImage: inputImage))

        let outputBuffer = try VImageBufferWrapper(image: vImage_Buffer(width: inputImage.width, height: inputImage.height, bitsPerPixel: 8))

        guard let inputImageFormat = vImage_CGImageFormat(cgImage: inputImage),
              let outputImageFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)) else{
            throw PipelineError.genericError("Cannot create the I/O Image format.")
        }
        
        let converter = try vImageConverter.make(sourceFormat: inputImageFormat, destinationFormat: outputImageFormat)
        try converter.convert(source: inputBuffer.image, destination: &outputBuffer.image)

        self.outputs.removeAll()
        self.outputs.append(.vimageBuffer(outputBuffer))
        /*
        let inputImage: CGImage
        var outputBuffer: VImageBufferWrapper
        
        switch(self.inputs.count, self.inputs[0]){
        case (1, .image(let image)):
            inputImage = image
        default:
            throw PipelineError.invalidInput("GrayscaleConverterStep requires one input of type CGImage.")
        }
        
        if self.outputs.count == 0{
            guard let buffer = try? vImage_Buffer(width: inputImage.width, height: inputImage.height, bitsPerPixel: 8) else{
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
        
        guard var inputBuffer = try? vImage_Buffer(cgImage: inputImage) else{
            throw PipelineError.creationError("GrayscaleConverterStep cannot create the input image buffer.")
        }
        
        guard let inputImageFormat = vImage_CGImageFormat(cgImage: inputImage) else{
            throw PipelineError.creationError("GrayscaleConverterStep cannot create the input image format.")
        }
        
        guard let outputImageFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)) else{
            throw PipelineError.creationError("GrayscaleConverterStep cannot create the output image format.")
        }
        
        guard let converter = try? vImageConverter.make(sourceFormat: inputImageFormat, destinationFormat: outputImageFormat) else{
            throw PipelineError.creationError("GrayscaleConverterStep cannot create the image converter.")
        }
        
        if kvImageNoError != vImageConvert_AnyToAny(converter, &inputBuffer, &outputBuffer.image, nil, vImage_Flags(kvImageNoFlags)){
            throw PipelineError.genericError("GrayscaleConverterStep cannot convert the image.")
        }
        
        if self.outputs.count == 0{
            self.outputs.append(.vimageBuffer(outputBuffer))
        }else{
            self.outputs[0] = .vimageBuffer(outputBuffer)
        }

        inputBuffer.free()
        */
    }
}
