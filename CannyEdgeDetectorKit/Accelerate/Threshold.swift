//
//  Threshold.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 21/03/2021.
//

import Foundation
import Accelerate

class Threshold{
    var thresholdOutput: VImageBufferWrapper
    var hysteresisOutput: VImageBufferWrapper
    var highThresholdRatio: Float
    var lowThresholdRatio: Float
    var strong: UInt8
    var weak: UInt8
    
    init(){
        self.thresholdOutput = VImageBufferWrapper()
        self.hysteresisOutput = VImageBufferWrapper()
        self.highThresholdRatio = 0.11
        self.lowThresholdRatio = 0.03
        self.strong = 255
        self.weak = 75
    }
    
    func compute(input: VImageBufferWrapper) -> VImageBufferWrapper{
        self.thresholdOutput.allocIfNeeded(image: input.image, bitsPerPixel: 8, contiguous: true)
        self.hysteresisOutput.allocIfNeeded(image: input.image, bitsPerPixel: 8, contiguous: true)
        
        let inputBuffer = input.bufferPointer(type: UInt8.self)
        let thresholdBuffer = self.thresholdOutput.mutableBufferPointer(type: UInt8.self)
        let hysteresisBuffer = self.hysteresisOutput.mutableBufferPointer(type: UInt8.self)
        
        thresholdBuffer.initialize(repeating: 0)
        hysteresisBuffer.initialize(repeating: 0)
        
        guard let maxValue = inputBuffer.max() else {return input}
        let highThreshold = UInt8(Float(maxValue) * self.highThresholdRatio)
        let lowThreshold = UInt8(Float(highThreshold) * self.lowThresholdRatio)
        
        for (index, pixel) in inputBuffer.enumerated(){
            if pixel >= highThreshold{
                thresholdBuffer[index] = self.strong
            } else if lowThreshold <= pixel && pixel < highThreshold{
                thresholdBuffer[index] = self.weak
            }
        }
        
        let width = Int(input.image.width)
        let baseAddress = self.thresholdOutput.image.data.assumingMemoryBound(to: UInt8.self)
        var previous = UnsafeBufferPointer<UInt8>(start: baseAddress, count: width)
        var actual = UnsafeBufferPointer<UInt8>(start: baseAddress + width, count: width)
        var next = UnsafeBufferPointer<UInt8>(start: baseAddress + 2 * width, count: width)
        
        for row in 1..<Int(input.image.height)-1{
            for column in 1..<Int(input.image.width)-1{
                let value = actual[column]
                
                if value != self.weak {continue}
                
                if previous[column - 1] == self.strong || previous[column] == self.strong || previous[column + 1] == self.strong
                    || actual[column - 1] == self.strong || actual[column + 1] == self.strong
                    || next[column - 1] == self.strong || next[column] == self.strong || next[column + 1] == self.strong{
                    hysteresisBuffer[row * width + column] = self.strong
                }
            }
            
            previous = actual
            actual = next
            next = UnsafeBufferPointer<UInt8>(start: baseAddress + row * width, count: width)
        }
        
        return self.hysteresisOutput
    }
}
