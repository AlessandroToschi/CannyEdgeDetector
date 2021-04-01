//
//  AccelerateDetector.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 17/02/2021.
//

import Foundation
import Accelerate
/*
public class AccelerateDetector: Detector{
    
    public init(){
        
    }
    public func compute(image: CGImage) -> CGImage? {
        guard let sourceImageFormat = vImage_CGImageFormat(cgImage: image) else{
            return nil
        }
        guard let grayImageFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        ) else{
            return nil
        }
        guard let imageConverter = try? vImageConverter.make(
                sourceFormat: sourceImageFormat,
                destinationFormat: grayImageFormat
        ) else{
            return nil
        }
        
        guard var sourceBuffer = try? vImage_Buffer(cgImage: image) else{
            return nil
        }
        
        guard var destinationBuffer = try? vImage_Buffer(
                width: image.width,
                height: image.height,
                bitsPerPixel: grayImageFormat.bitsPerPixel
        ) else{
            return nil
        }
        
        if kvImageNoError != vImageConvert_AnyToAny(
            imageConverter,
            &sourceBuffer,
            &destinationBuffer,
            nil,
            vImage_Flags(kvImagePrintDiagnosticsToConsole)
        ){
            return nil
        }
        
        guard var boxFilterBuffer = try? vImage_Buffer(
                width: image.width,
                height: image.height,
                bitsPerPixel: grayImageFormat.bitsPerPixel
        )else {
            return nil
        }
        
        if kvImageNoError != vImageBoxConvolve_Planar8(
            &destinationBuffer,
            &boxFilterBuffer,
            nil,
            0,
            0,
            3,
            3,
            0,
            vImage_Flags(kvImageEdgeExtend)
        ){
            return nil
        }
        
        /*
        guard var floatBuffer = try? vImage_Buffer(width: image.width, height: image.height, bitsPerPixel: 32) else {
            return nil
        }
        
        if kvImageNoError != vImageConvert_Planar8toPlanarF(
            &boxFilterBuffer,
            &floatBuffer,
            1.0,
            0.0,
            vImage_Flags(kvImagePrintDiagnosticsToConsole)
        ){
            return nil
        }
        */
        let floatBuffer = [Float](unsafeUninitializedCapacity: image.width * image.height) {
            buffer, initializedCount in
            
            var floatBuffe = vImage_Buffer(data: buffer.baseAddress,
                                            height: sourceBuffer.height,
                                            width: sourceBuffer.width,
                                            rowBytes: image.width * MemoryLayout<Float>.size)
            
            vImageConvert_Planar8toPlanarF(&boxFilterBuffer,
                                           &floatBuffe,
                                           0.0, 1.0,
                                           vImage_Flags(kvImageNoFlags))
            
            initializedCount = image.width * image.height
        }
        
        
        let Ix = vDSP.convolve(floatBuffer, rowCount: image.height, columnCount: image.width, with3x3Kernel: [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0])
        let Iy = vDSP.convolve(floatBuffer, rowCount: image.height, columnCount: image.width, with3x3Kernel: [1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0])
        let G = vDSP.hypot(Ix, Iy)
        let theta = vForce.atan(G)

        

        let resultImage = try? boxFilterBuffer.createCGImage(format: grayImageFormat)

        
        defer{
            sourceBuffer.free()
            destinationBuffer.free()
            boxFilterBuffer.free()
            //floatBuffer.free()
        }
        
        return resultImage
    }
    
    public func setup() -> Bool {
        return false
    }
}
 */

public class AccelerateDetector: Detector{
    let pipeline: Pipeline
    
    public init(){
        self.pipeline = Pipeline()
                        .addStep(step: GrayscaleConverterStep())
                        .addStep(step: BoxFilterStep())
                        .addStep(step: GradientStep())
                        .addStep(step: NonMaxSuppressionStep())
    }
    
    public func setup() -> Bool {
        return true
    }
    
    public func compute(image: CGImage) -> CGImage? {
        do {
            try self.pipeline.execute(input: .image(image))
            guard let outputs = self.pipeline.outputs else{
                return nil
            }
            let grayImageFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
            let grayBuffer = self.pipeline.outputs![0].associatedValue(type: VImageBufferWrapper.self)!
            //var grayBuffer = try! vImage_Buffer(width: image.width, height: image.height, bitsPerPixel: 8)
            //defer{
            //    grayBuffer.free()
            //}
            //var floatBuffer: [Float]
            //switch(outputs[0]){
            //case .floatBuffer(let buffer):
            //    floatBuffer = buffer
            //default:
            //    return nil
            //}
            /*
            floatBuffer.withUnsafeMutableBytes{
                bufferPointer in
                var floatBufferTemp = vImage_Buffer(data: bufferPointer.baseAddress, height: vImagePixelCount(image.height), width: vImagePixelCount(image.width), rowBytes: image.width * MemoryLayout<Float>.size)
                vImageConvert_PlanarFtoPlanar8(&floatBufferTemp, &grayBuffer, 255.0, 0.0, vImage_Flags(kvImageNoFlags))
            }
            */
            return try? grayBuffer.image.createCGImage(format: grayImageFormat)
            
        } catch PipelineError.creationError(let a) {
            print(a)
            return nil
        }
        catch PipelineError.genericError(let a) {
            print(a)
            return nil
        }
        catch PipelineError.invalidInput(let a) {
            print(a)
            return nil
        }
        catch{
            return nil
        }
    }
}
