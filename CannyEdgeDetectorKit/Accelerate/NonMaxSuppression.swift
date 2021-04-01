//
//  NonMaxSuppression.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/03/2021.
//

import Foundation
import Accelerate

class NonMaxSuppression{
    var output: VImageBufferWrapper
    
    init(){
        self.output = VImageBufferWrapper()
    }
    
    func compute(magnitude: VImageBufferWrapper, theta: VImageBufferWrapper) -> VImageBufferWrapper{
        self.output.allocIfNeeded(image: magnitude.image, bitsPerPixel: 8, contiguous: true)
        
        let outputPointer = self.output.mutableBufferPointer(type: UInt8.self)
        let thetaPointer = theta.bufferPointer(type: Float.self)
        
        outputPointer.initialize(repeating: 0)
        
        let width = Int(magnitude.image.width)
        let baseAddress = magnitude.image.data.assumingMemoryBound(to: UInt8.self)
        var previous = UnsafeBufferPointer<UInt8>(start: baseAddress, count: width)
        var actual = UnsafeBufferPointer<UInt8>(start: baseAddress + width, count: width)
        var next = UnsafeBufferPointer<UInt8>(start: baseAddress + 2 * width, count: width)
        
        
        for row in 1..<Int(magnitude.image.height)-1{
            for column in 1..<Int(magnitude.image.width)-1{
                let index = row * width + column
                let value = actual[column]
                var angle = thetaPointer[index] * (180.0 / Float.pi)
                if angle < 0.0{
                    angle += 180.0
                }
                
                var x: UInt8 = 255
                var y: UInt8 = 255
                
                if (angle >= 0.0 && angle < 22.5) || (angle >= 157.5 && angle <= 180.0){
                    x = actual[column + 1]
                    y = actual[column - 1]
                }
                else if (angle >= 22.5 && angle < 67.5){
                    x = next[column - 1]
                    y = previous[column + 1]
                }
                else if (angle >= 67.5 && angle < 112.5){
                    x = next[column]
                    y = previous[column]
                }
                else{
                    x = previous[column - 1]
                    y = next[column + 1]
                }
                outputPointer[index] = (value >= x && value >= y) ? value : 0

                previous = actual
                actual = next
                next = UnsafeBufferPointer<UInt8>(start: baseAddress + row * width, count: width)
            }
        }
        return self.output
    }
}
