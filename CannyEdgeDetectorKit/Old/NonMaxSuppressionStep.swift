//
//  NonMaxSuppressionStep.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 21/02/2021.
//

import Foundation
import Accelerate

class NonMaxSuppressionStep: PipelineStep{
    override func execute() throws {
        try self.checkNumberOfInputs(expected: 2)
        
        let imageBuffer = try self.getInputData(index: 0, type: VImageBufferWrapper.self)
        let imageBufferPointer = imageBuffer.image.data.assumingMemoryBound(to: UInt8.self)
        let outputBuffer = try VImageBufferWrapper(image: vImage_Buffer(width: Int(imageBuffer.image.width), height: Int(imageBuffer.image.height), bitsPerPixel: 8))
        let outputBufferPointer = outputBuffer.image.data.assumingMemoryBound(to: UInt8.self)
        let thetaBuffer = try self.getInputData(index: 1, type: [Float].self)
        let width = Int(imageBuffer.image.width)
        let height = Int(imageBuffer.image.height)
        let count = width * height
        
        //var suppressedImageBuffer = [Float](repeating: 0.0, count: count)
        /*
        print(thetaBuffer.count)
        thetaBuffer.withUnsafeMutableBytes{
            bufferPointer in
            print(bufferPointer.count)
            let typedBufferPointer = bufferPointer.bindMemory(to: Float.self)
            let chunks = typedBufferPointer.count / 16
            var offset = 0
            for _ in 0..<chunks{
                var angles = SIMD16<Float>(typedBufferPointer[offset..<offset+16])
                angles *= 180.0 / Float.pi
                let adjustedAngles = angles + 180.0
                let mask = angles .< 0.0
                angles.replace(with: adjustedAngles, where: mask)
                bufferPointer.storeBytes(of: angles, toByteOffset: offset, as: SIMD16<Float>.self)
                offset += 16
            }
            for i in offset..<typedBufferPointer.count{
                let angle = typedBufferPointer[i] * 180.0 / Float.pi
                typedBufferPointer[i] = angle < 0 ? angle + 180.0 : angle
            }
        }
        */
        for row in 1..<(height - 1){
            for column in 1..<(width - 1){
                let linearIndex = row * width + column
                var q: UInt8 = 0
                var r: UInt8 = 0
                var angle = thetaBuffer[linearIndex] * (180.0 / Float.pi)
                if angle < 0.0{
                    angle += 180.0
                }
                switch angle{
                case let x where (0.0 <= x && x < 22.5) || (157.5 <= x && x <= 180.0):
                    q = imageBufferPointer[linearIndex - 1]
                    r = imageBufferPointer[linearIndex + 1]
                case let x where (22.5 <= x && x < 67.5):
                    q = imageBufferPointer[linearIndex + width - 1]
                    r = imageBufferPointer[linearIndex - width + 1]
                case let x where (67.5 <= x && x < 112.5):
                    q = imageBufferPointer[linearIndex + width]
                    r = imageBufferPointer[linearIndex - width]
                case let x where (112.5 <= x && x < 157.5):
                    q = imageBufferPointer[linearIndex - width - 1]
                    r = imageBufferPointer[linearIndex + width + 1]
                default:
                    continue
                }
                //print(imageBufferPointer[linearIndex], q, r)
                if imageBufferPointer[linearIndex] >= q && imageBufferPointer[linearIndex] >= r{
                    outputBufferPointer[linearIndex] = imageBufferPointer[linearIndex]
                } else{
                    outputBufferPointer[linearIndex] = 0
                }
            }
        }
        
        self.outputs.removeAll()
        self.outputs.append(.vimageBuffer(outputBuffer))
    }
}
