//
//  TimerConsumer.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 07/03/2021.
//

import Foundation
import AVFoundation

class TimerConsumer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    var lastTimestamp: DispatchTime
    var liveView: LiveView?
    
    override init(){
        self.lastTimestamp = DispatchTime.now()
    }
    
    func writeChroma(imageBuffer: CVPixelBuffer){
        let size = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1) * CVPixelBufferGetHeightOfPlane(imageBuffer, 1)
        let chromaPlanePointer = UnsafeRawPointer(CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1))!
        let data = Data(bytes: chromaPlanePointer, count: size)
        try! data.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/chroma.bin"))
    }
    
    func writeLuma(imageBuffer: CVPixelBuffer){
        let size = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0) * CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let lumaPlanePointer = UnsafeRawPointer(CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0))!
        let data = Data(bytes: lumaPlanePointer, count: size)
        try! data.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/luma.bin"))
    }
    
    func write(imageBuffer: CVPixelBuffer){
        let size = CVPixelBufferGetDataSize(imageBuffer)
        let pointer = UnsafeRawPointer(CVPixelBufferGetBaseAddress(imageBuffer))!
        let data = Data(bytes: pointer, count: size)
        try! data.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/web.bin"))
    }
    
    @objc func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = DispatchTime.now()
        let elapsed = (now.uptimeNanoseconds - self.lastTimestamp.uptimeNanoseconds) / 1_000_000
        self.lastTimestamp = now
        print(elapsed)
        
        guard let imageBuffer = sampleBuffer.imageBuffer else{
            return
        }
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }
        /*
        print("Width: \(CVPixelBufferGetWidth(imageBuffer)), Height: \(CVPixelBufferGetHeight(imageBuffer))")
        print("Luma Width: \(CVPixelBufferGetWidthOfPlane(imageBuffer, 0)), Chroma Width: \(CVPixelBufferGetWidthOfPlane(imageBuffer, 1))")
        print("Luma Height: \(CVPixelBufferGetHeightOfPlane(imageBuffer, 0)), Chroma Height: \(CVPixelBufferGetHeightOfPlane(imageBuffer, 1))")
        print("Bytes per row: \(CVPixelBufferGetBytesPerRow(imageBuffer)), Luma: \(CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)), Chroma: \(CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1))")
        print("is Planar: \(CVPixelBufferIsPlanar(imageBuffer)), Planar count: \(CVPixelBufferGetPlaneCount(imageBuffer))")
        print("Size: \(CVPixelBufferGetDataSize(imageBuffer))")
 */
        //self.writeLuma(imageBuffer: imageBuffer)
        //self.write(imageBuffer: imageBuffer)
        //self.writeChroma(imageBuffer: imageBuffer)
        let lumaWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let lumaHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let bytes = UnsafePointer<UInt8>(CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)?.assumingMemoryBound(to: UInt8.self))!
        let size = lumaBytesPerRow * lumaHeight
        let dataProvider = CGDataProvider(data: CFDataCreate(nil, bytes, size))!
        
        guard let image = CGImage(width: lumaWidth, height: lumaHeight, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: lumaBytesPerRow, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else{
            print("cannot create the image")
            return
        }
        
        DispatchQueue.main.async {
            self.liveView?.image = image
        }
    }
}
