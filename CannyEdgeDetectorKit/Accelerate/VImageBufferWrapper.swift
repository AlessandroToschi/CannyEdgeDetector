//
//  VImageBufferWrapper.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 28/02/2021.
//

import Foundation
import Accelerate

class VImageBufferWrapper{
    var image: vImage_Buffer
    
    convenience init(){
        self.init(image: vImage_Buffer())
    }
    
    init(image: vImage_Buffer){
        self.image = image
    }
    
    func allocIfNeeded(image: vImage_Buffer, bitsPerPixel: UInt32, contiguous: Bool = false){
        if self.image.width == image.width && self.image.height == image.height{
            return
        }
        self.image.free()
        
        var rowBytes = Int(image.width) * Int(bitsPerPixel) / 8
        var size = rowBytes * Int(image.height)
        var alignment = 16
        
        if !contiguous,
           let preferredOptions = try? vImage_Buffer.preferredAlignmentAndRowBytes(width: Int(image.width), height: Int(image.width), bitsPerPixel: bitsPerPixel) {
            rowBytes = preferredOptions.rowBytes
            size = preferredOptions.rowBytes * Int(image.height)
            alignment = preferredOptions.alignment
        }
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        pointer.initializeMemory(as: UInt8.self, repeating: 0, count: size)
        self.image = vImage_Buffer(data: pointer, height: image.height, width: image.width, rowBytes: rowBytes)
    }
    
    func mutableBufferPointer<T>(type: T.Type) -> UnsafeMutableBufferPointer<T>{
        let size = self.image.rowBytes * Int(self.image.height)
        let rawPointer = UnsafeMutableRawBufferPointer(start: self.image.data, count: size)
        return rawPointer.bindMemory(to: type)
    }
    
    func bufferPointer<T>(type: T.Type) -> UnsafeBufferPointer<T>{
        let size = self.image.rowBytes * Int(self.image.height)
        let rawPointer = UnsafeRawBufferPointer(start: self.image.data, count: size)
        return rawPointer.bindMemory(to: type)
    }
    
    deinit {
        self.image.free()
    }
}
