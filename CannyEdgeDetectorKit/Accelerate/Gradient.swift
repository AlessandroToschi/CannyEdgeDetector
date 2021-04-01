//
//  Gradient.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 14/03/2021.
//

import Foundation
import Accelerate

class Gradient{
    var imageFloat: VImageBufferWrapper
    var magnitudeFloat: VImageBufferWrapper
    var magnitudeOutput: VImageBufferWrapper
    var theta: VImageBufferWrapper
    var dx: VImageBufferWrapper
    var dy: VImageBufferWrapper
    var temporaryBuffer: TemporaryBuffer
    let dxKernel: [Float] = [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0]
    let dyKernel: [Float] = [1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0]
    
    init(){
        self.imageFloat = VImageBufferWrapper()
        self.dx = VImageBufferWrapper()
        self.dy = VImageBufferWrapper()
        self.magnitudeFloat = VImageBufferWrapper()
        self.magnitudeOutput = VImageBufferWrapper()
        self.theta = VImageBufferWrapper()
        self.temporaryBuffer = TemporaryBuffer()
    }
    
    func compute(input: VImageBufferWrapper) -> (VImageBufferWrapper, VImageBufferWrapper){
        self.imageFloat.allocIfNeeded(image: input.image, bitsPerPixel: 32)
        
        self.dx.allocIfNeeded(image: input.image, bitsPerPixel: 32, contiguous: true)
        self.dy.allocIfNeeded(image: input.image, bitsPerPixel: 32, contiguous: true)
        
        self.magnitudeFloat.allocIfNeeded(image: input.image, bitsPerPixel: 32, contiguous: true)
        self.magnitudeOutput.allocIfNeeded(image: input.image, bitsPerPixel: 8)
        
        self.theta.allocIfNeeded(image: input.image, bitsPerPixel: 32, contiguous: true)
        
        self.convertImageToFloat(input: &input.image)
        self.computeGradient(input: &self.imageFloat.image, gradient: &self.dx.image, kernel: self.dxKernel)
        self.computeGradient(input: &self.imageFloat.image, gradient: &self.dy.image, kernel: self.dyKernel)
        
        var c = self.magnitudeFloat.mutableBufferPointer(type: Float.self)
        let d = self.theta.mutableBufferPointer(type: Float.self)
        var e = Int32(self.dx.image.width * self.dy.image.height)
        
        vDSP.hypot(self.dx.bufferPointer(type: Float.self), self.dy.bufferPointer(type: Float.self), result: &c)
        let scaleFactor = 255.0 / vDSP.maximum(c)
        vDSP.multiply(scaleFactor, c, result: &c)
        
        
        vvatan2f(d.baseAddress!, self.dy.bufferPointer(type: Float.self).baseAddress!, self.dx.bufferPointer(type: Float.self).baseAddress!, &e)
        
        vImageConvert_PlanarFtoPlanar8(&self.magnitudeFloat.image, &self.magnitudeOutput.image, 255.0, 0.0, vImage_Flags(kvImageNoFlags))
        
        return (self.magnitudeOutput, self.theta)
    }
    
    func allocIfNeeded(buffer: inout [Float], image: vImage_Buffer){
        if image.width * image.height == buffer.count{
            return
        }
        buffer = [Float](repeating: 0.0, count: Int(image.width * image.height))
    }
    
    func convertImageToFloat(input: inout vImage_Buffer){
        vImageConvert_Planar8toPlanarF(&input, &self.imageFloat.image, 255.0, 0.0, vImage_Flags(kvImageNoFlags | kvImagePrintDiagnosticsToConsole))
    }
    
    func computeGradient(input: inout vImage_Buffer, gradient: inout vImage_Buffer, kernel: [Float]){
        kernel.withUnsafeBufferPointer{
            bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else {return}
            let temporarySize = vImageConvolve_PlanarF(&input, &gradient, nil, 0, 0, baseAddress, 3, 3, 0, vImage_Flags(kvImageGetTempBufferSize | kvImageEdgeExtend))
            self.temporaryBuffer.reallocIfNeeded(newSize: temporarySize)
            vImageConvolve_PlanarF(&input, &gradient, self.temporaryBuffer.buffer, 0, 0, baseAddress, 3, 3, 0, vImage_Flags(kvImageEdgeExtend))
        }
    }
    
    func allocGradientIfNeeded(buffer: inout VImageBufferWrapper, input: vImage_Buffer){
        if buffer.image.width == input.width && buffer.image.height == input.height{
            return
        }
        let rowBytes = Int(input.width) * MemoryLayout<Float>.size
        let size = rowBytes * Int(input.height)
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 16)
        let image = vImage_Buffer(data: pointer, height: input.height, width: input.width, rowBytes: rowBytes)
        buffer = VImageBufferWrapper(image: image)
    }
}
