//
//  MetalDetector.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 21/03/2021.
//

import Foundation
import Metal
import MetalPerformanceShaders
import Accelerate

public class MetalDetector: DetectorStrategy{
    public var outputFormat: vImage_CGImageFormat
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    var textureCache: CVMetalTextureCache!
    
    var boxTexture: MTLTexture!
    var dxTexture: MTLTexture!
    var dyTexture: MTLTexture!
    var magnitudeTexture: MTLTexture!
    var minMaxTexture: MTLTexture!
    var scaledMagnitudeTexture: MTLTexture!
    var suppressedMagnitudeTexture: MTLTexture!
    var thetaTexture: MTLTexture!
    var thresholdsBuffer: MTLBuffer!
    var minMaxBuffer: MTLBuffer!
    var thresholdTexture: MTLTexture!
    var outputTexture: MTLTexture!
    
    var boxFilter: MPSImageBox
    var dxFilter: MPSImageConvolution
    var dyFilter: MPSImageConvolution
    var minMaxFilter: MPSImageStatisticsMinAndMax
    
    var hypotComputePipelineState: MTLComputePipelineState!
    var scaleComputePipelineState: MTLComputePipelineState!
    var atan2ComputePipelineState: MTLComputePipelineState!
    var nonMaxSuppressionComputePipelineState: MTLComputePipelineState!
    var thresholdComputePipelineState: MTLComputePipelineState!
    var hysteresisComputePipelineState: MTLComputePipelineState!
    
    let dxKernel: [Float] = [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0]
    let dyKernel: [Float] = [1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0]
    let thresholds: [Float] = [0.11, 0.03]
    let minMaxPixels: [Float] = [75.0 / 255.0, 1.0]
    
    public init(){
        self.outputFormat = vImage_CGImageFormat()
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else{
            fatalError("No GPU available.")
        }
        self.device = device
        self.commandQueue = commandQueue

        guard let libraryFilePath = Bundle(for: MetalDetector.self).path(forResource: "default", ofType: "metallib"),
              let library = try? device.makeLibrary(filepath: libraryFilePath) else{
            fatalError("Cannot find the metal library")
        }
        self.library = library
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &self.textureCache)
        
        self.boxFilter = MPSImageBox(device: self.device, kernelWidth: 3, kernelHeight: 3)
        self.dxFilter = MPSImageConvolution(device: self.device, kernelWidth: 3, kernelHeight: 3, weights: self.dxKernel)
        self.dyFilter = MPSImageConvolution(device: self.device, kernelWidth: 3, kernelHeight: 3, weights: self.dyKernel)
        self.minMaxFilter = MPSImageStatisticsMinAndMax(device: self.device)
    }
    
    public func prepare(width: Int, height: Int) {
        guard let hypotState = computePipelineState(for: "hypot_kernel"),
              let scaleState = self.computePipelineState(for: "scale_kernel"),
              let atan2State = self.computePipelineState(for: "atan2_kernel"),
              let nonMaxSuppressionState = self.computePipelineState(for: "non_max_suppression_kernel"),
              let thresholdState = self.computePipelineState(for: "threshold_kernel"),
              let hysteresisState = self.computePipelineState(for: "hysteresis_kernel") else{
            fatalError("Cannot create the compute kernels and states.")
        }
        
        self.hypotComputePipelineState = hypotState
        self.scaleComputePipelineState = scaleState
        self.atan2ComputePipelineState = atan2State
        self.nonMaxSuppressionComputePipelineState = nonMaxSuppressionState
        self.thresholdComputePipelineState = thresholdState
        self.hysteresisComputePipelineState = hysteresisState
        
        guard let boxTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let dxTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let dyTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let magnitudeTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r32Float)),
              let minMaxTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: 2, height: 1, pixelFormat: .r32Float)),
              let scaledMagnitudeTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let thetaTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r32Float)),
              let suppressedTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let thresholdsBuffer = device.makeBuffer(bytes: thresholds, length: thresholds.count * MemoryLayout<Float>.size, options: .storageModeManaged),
              let minMaxPixelsBuffer = device.makeBuffer(bytes: minMaxPixels, length: minMaxPixels.count * MemoryLayout<Float>.size, options: .storageModeManaged),
              let thresholdTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)),
              let outputTexture = device.makeTexture(descriptor: self.makeTextureDescriptor(width: width, height: height, pixelFormat: .r8Unorm)) else{
            fatalError("Cannot create the textures and buffers")
        }

        self.boxTexture = boxTexture
        self.dxTexture = dxTexture
        self.dyTexture = dyTexture
        self.magnitudeTexture = magnitudeTexture
        self.minMaxTexture = minMaxTexture
        self.scaledMagnitudeTexture = scaledMagnitudeTexture
        self.thetaTexture = thetaTexture
        self.suppressedMagnitudeTexture = suppressedTexture
        self.thresholdsBuffer = thresholdsBuffer
        self.minMaxBuffer = minMaxPixelsBuffer
        self.thresholdTexture = thresholdTexture
        self.outputTexture = outputTexture
    }
    
    public func detect(_ imageBuffer: CVPixelBuffer) throws -> CGImage? {
        let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        
        guard let lumaTexture = self.getTexture(imageBuffer: imageBuffer, planeIndex: 0) else{
            return nil
        }
        
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else{
            return nil
        }
        
        self.boxFilter.encode(commandBuffer: commandBuffer, sourceTexture: lumaTexture, destinationTexture: boxTexture)
        self.dxFilter.encode(commandBuffer: commandBuffer, sourceTexture: boxTexture, destinationTexture: dxTexture)
        self.dyFilter.encode(commandBuffer: commandBuffer, sourceTexture: boxTexture, destinationTexture: dyTexture)
        
        let magnitudeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        magnitudeCommandEncoder?.setComputePipelineState(self.hypotComputePipelineState)
        magnitudeCommandEncoder?.setTexture(self.dxTexture, index: 0)
        magnitudeCommandEncoder?.setTexture(self.dyTexture, index: 1)
        magnitudeCommandEncoder?.setTexture(self.magnitudeTexture, index: 2)
        magnitudeCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.hypotComputePipelineState))
        magnitudeCommandEncoder?.endEncoding()

        self.minMaxFilter.encode(commandBuffer: commandBuffer, sourceTexture: magnitudeTexture, destinationTexture: minMaxTexture)

        let scaleCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        scaleCommandEncoder?.setComputePipelineState(self.scaleComputePipelineState)
        scaleCommandEncoder?.setTexture(self.magnitudeTexture, index: 0)
        scaleCommandEncoder?.setTexture(self.minMaxTexture, index: 1)
        scaleCommandEncoder?.setTexture(self.scaledMagnitudeTexture, index: 2)
        scaleCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.scaleComputePipelineState))
        scaleCommandEncoder?.endEncoding()

        let angleCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        angleCommandEncoder?.setComputePipelineState(self.atan2ComputePipelineState)
        angleCommandEncoder?.setTexture(self.dxTexture, index: 0)
        angleCommandEncoder?.setTexture(self.dyTexture, index: 1)
        angleCommandEncoder?.setTexture(self.thetaTexture, index: 2)
        angleCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.atan2ComputePipelineState))
        angleCommandEncoder?.endEncoding()
            
        let nonMaxSuppressionCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        nonMaxSuppressionCommandEncoder?.setComputePipelineState(self.nonMaxSuppressionComputePipelineState)
        nonMaxSuppressionCommandEncoder?.setTexture(self.scaledMagnitudeTexture, index: 0)
        nonMaxSuppressionCommandEncoder?.setTexture(self.thetaTexture, index: 1)
        nonMaxSuppressionCommandEncoder?.setTexture(self.suppressedMagnitudeTexture, index: 2)
        nonMaxSuppressionCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.nonMaxSuppressionComputePipelineState))
        nonMaxSuppressionCommandEncoder?.endEncoding()
            
        minMaxFilter.encode(commandBuffer: commandBuffer, sourceTexture: self.suppressedMagnitudeTexture, destinationTexture: minMaxTexture)
            
        let thresholdCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        thresholdCommandEncoder?.setComputePipelineState(self.thresholdComputePipelineState)
        thresholdCommandEncoder?.setTexture(self.suppressedMagnitudeTexture, index: 0)
        thresholdCommandEncoder?.setTexture(self.minMaxTexture, index: 1)
        thresholdCommandEncoder?.setTexture(self.thresholdTexture, index: 2)
        thresholdCommandEncoder?.setBuffer(self.thresholdsBuffer, offset: 0, index: 0)
        thresholdCommandEncoder?.setBuffer(self.minMaxBuffer, offset: 0, index: 1)
        thresholdCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.thresholdComputePipelineState))
        thresholdCommandEncoder?.endEncoding()
            
            
        let hysteresisCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        hysteresisCommandEncoder?.setComputePipelineState(self.hysteresisComputePipelineState)
        hysteresisCommandEncoder?.setTexture(self.thresholdTexture, index: 0)
        hysteresisCommandEncoder?.setTexture(self.outputTexture, index: 1)
        hysteresisCommandEncoder?.setBuffer(self.minMaxBuffer, offset: 0, index: 0)
        hysteresisCommandEncoder?.dispatchThreads(MTLSizeMake(width, height, 1), threadsPerThreadgroup: threadsPerThreadsgroup(computePipelineState: self.hysteresisComputePipelineState))
        hysteresisCommandEncoder?.endEncoding()
            

        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder?.synchronize(resource: self.outputTexture)
        blitCommandEncoder?.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        let imagePointer = UnsafeMutableRawPointer.allocate(byteCount: width * height, alignment: 64)
                
        self.outputTexture.getBytes(imagePointer, bytesPerRow: width, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        let dataProvider = CGDataProvider(data: CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, imagePointer.assumingMemoryBound(to: UInt8.self), width * height, nil))
        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: dataProvider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        return image
    }
    
    func getTexture(imageBuffer: CVPixelBuffer, planeIndex: Int) -> MTLTexture?{
        let width = CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex)
        var x: CVMetalTexture? = nil
        guard CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                self.textureCache,
                imageBuffer,
                nil,
                .r8Unorm,
                width,
                height,
                planeIndex,
                &x
              ) == kCVReturnSuccess,
              let metalTexture = x,
              let texture = CVMetalTextureGetTexture(metalTexture) else{
            return nil
        }
        
        return texture
    }
    
    func makeTextureDescriptor(width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTextureDescriptor{
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.textureType = .type2D
        textureDescriptor.resourceOptions = .storageModeManaged
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        return textureDescriptor
    }

    func threadsPerThreadsgroup(computePipelineState: MTLComputePipelineState) -> MTLSize{
        let w = computePipelineState.threadExecutionWidth
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
        return MTLSizeMake(w, h, 1)
    }
    
    func computePipelineState(for kernelName: String) -> MTLComputePipelineState?{
        guard let kernel = self.library.makeFunction(name: kernelName) else{
            return nil
        }
        return try? self.device.makeComputePipelineState(function: kernel)
    }
}
