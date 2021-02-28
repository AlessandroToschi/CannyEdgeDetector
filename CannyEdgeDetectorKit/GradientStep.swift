//
//  GradientStep.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation
import Accelerate

class GradientStep: PipelineStep{
    var dxBuffer: VImageBufferWrapper
    var dyBuffer: VImageBufferWrapper
    let dxKernel: [Float] = [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0]
    let dyKernel: [Float] = [1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0]
    
    override init() {
        self.dxBuffer = VImageBufferWrapper(image: vImage_Buffer())
        self.dyBuffer = VImageBufferWrapper(image: vImage_Buffer())
        super.init()
    }
    
    func resizeIfNeeded(reference: inout VImageBufferWrapper, target: VImageBufferWrapper) throws{
        if reference.image.width != target.image.width || reference.image.height != target.image.height{
            reference = try VImageBufferWrapper(image: vImage_Buffer.init(width: Int(target.image.width), height: Int(target.image.height), bitsPerPixel: 32))
        }
    }
    
    override func execute() throws {
        try self.checkNumberOfInputs(expected: 1)
        
        let inputBuffer = try self.getInputData(index: 0, type: VImageBufferWrapper.self)
        let count = Int(inputBuffer.image.width * inputBuffer.image.height)
        
        let inputFloatBuffer = try VImageBufferWrapper(image: vImage_Buffer(width: Int(inputBuffer.image.width), height: Int(inputBuffer.image.height), bitsPerPixel: 32))
        
        vImageConvert_Planar8toPlanarF(&inputBuffer.image, &inputFloatBuffer.image, 255.0, 0.0, vImage_Flags(kvImageNoFlags))
        
        try self.resizeIfNeeded(reference: &self.dxBuffer, target: inputFloatBuffer)
        try self.resizeIfNeeded(reference: &self.dyBuffer, target: inputFloatBuffer)
        
        try dxKernel.withUnsafeBufferPointer{
            bufferPointer in
            let error = vImageConvolve_PlanarF(&inputFloatBuffer.image,
                                               &self.dxBuffer.image,
                                               nil,
                                               0,
                                               0,
                                               bufferPointer.baseAddress,
                                               3,
                                               3,
                                               0.0,
                                               vImage_Flags(kvImageEdgeExtend)
            )
            if error != kvImageNoError{
                throw PipelineError.genericError("GradientStep cannot apply the Sobel operator")
            }
        }
        
        try dyKernel.withUnsafeBufferPointer{
            bufferPointer in
            let error = vImageConvolve_PlanarF(&inputFloatBuffer.image,
                                               &self.dyBuffer.image,
                                               nil,
                                               0,
                                               0,
                                               bufferPointer.baseAddress,
                                               3,
                                               3,
                                               0.0,
                                               vImage_Flags(kvImageEdgeExtend)
            )
            if error != kvImageNoError{
                throw PipelineError.genericError("GradientStep cannot apply the Sobel operator")
            }
        }
        
        let dx = try [Float](unsafeUninitializedCapacity: count){
            bufferPointer, ccount in
            let rowBytes = Int(self.dxBuffer.image.width) * MemoryLayout<Float>.size
            var buffer = vImage_Buffer(data: bufferPointer.baseAddress!, height: self.dxBuffer.image.height, width: self.dxBuffer.image.width, rowBytes: rowBytes)
            try self.dxBuffer.image.copy(destinationBuffer: &buffer, pixelSize: 4)
            ccount = count
        }
        
        let dy = try [Float](unsafeUninitializedCapacity: count){
            bufferPointer, ccount in
            let rowBytes = Int(self.dyBuffer.image.width) * MemoryLayout<Float>.size
            var buffer = vImage_Buffer(data: bufferPointer.baseAddress!, height: self.dyBuffer.image.height, width: self.dyBuffer.image.width, rowBytes: rowBytes)
            try self.dyBuffer.image.copy(destinationBuffer: &buffer, pixelSize: 4)
            ccount = count
        }
        
        //let dxBufferPointer = UnsafeBufferPointer<Float>(start: self.dxBuffer.image.data.assumingMemoryBound(to: Float.self), count: count)
        //let dyBufferPointer = UnsafeBufferPointer<Float>(start: self.dyBuffer.image.data.assumingMemoryBound(to: Float.self), count: count)
        
        let magnitude = vDSP.hypot(dx, dy)
        let angles = vForce.atan(magnitude)
        
        self.outputs.removeAll()
        self.outputs.append(.vimageBuffer(inputBuffer))
        self.outputs.append(.floatBuffer(angles))
        //self.outputs.append(.vimageBuffer(inputBuffer.copy(destinationBuffer: &<#T##vImage_Buffer#>, pixelSize: <#T##Int#>)))
        /*
        var inputBuffer: vImage_Buffer
        
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
        
        let count = Int(inputBuffer.width * inputBuffer.height)
        
        if self.floatBuffer == nil || self.floatBuffer?.count != count{
            self.floatBuffer = try [Float](unsafeUninitializedCapacity: count){
                bufferPointer, initializedCount in
                var floatBuffertTemp = vImage_Buffer(data: bufferPointer.baseAddress, height: inputBuffer.height, width: inputBuffer.width, rowBytes: Int(inputBuffer.width) * MemoryLayout<Float>.size)
                if kvImageNoError != vImageConvert_Planar8toPlanarF(&inputBuffer, &floatBuffertTemp, 255.0, 0.0, vImage_Flags(kvImageNoFlags)){
                    throw PipelineError.creationError("GradientStep cannot create the float  buffer.")
                }
                initializedCount = count
            }
        }else{
            try self.floatBuffer?.withUnsafeMutableBytes{
                bufferPointer in
                var floatBuffertTemp = vImage_Buffer(data: bufferPointer.baseAddress, height: inputBuffer.height, width: inputBuffer.width, rowBytes: Int(inputBuffer.width) * MemoryLayout<Float>.size)
                if kvImageNoError != vImageConvert_Planar8toPlanarF(&inputBuffer, &floatBuffertTemp, 255.0, 0.0, vImage_Flags(kvImageNoFlags)){
                    throw PipelineError.creationError("GradientStep cannot create the float  buffer.")
                }
            }
        }
        
        if self.dxBuffer == nil || self.dxBuffer?.count != count{
            self.dxBuffer = vDSP.convolve(self.floatBuffer!, withKernel: self.dxKernel)
        }else{
            vDSP.convolve(self.floatBuffer!, withKernel: self.dxKernel, result: &self.dxBuffer!)
        }
        
        if self.dyBuffer == nil || self.dyBuffer?.count != count{
            self.dyBuffer = vDSP.convolve(self.floatBuffer!, withKernel: self.dyKernel)
        }else{
            vDSP.convolve(self.floatBuffer!, withKernel: self.dyKernel, result: &self.dyBuffer!)
        }
        
        self.outputs.removeAll()
        
        let magnitude = vDSP.hypot(self.dxBuffer!, self.dyBuffer!)
        self.outputs.append(.floatBuffer(self.floatBuffer!))
        self.outputs.append(.floatBuffer(vForce.atan(magnitude)))
        self.outputs.append(.any(Int(inputBuffer.width)))
        self.outputs.append(.any(Int(inputBuffer.height)))
        */
    }
}
