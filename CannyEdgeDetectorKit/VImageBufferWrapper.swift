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
    
    func allocIfNeeded(image: vImage_Buffer, bitsPerPixel: UInt32){
        if self.image.width == image.width && self.image.height == image.height{
            return
        }
        self.image.free()
        
        var rowBytes = image.rowBytes
        var size = rowBytes * Int(image.height)
        var alignment = 16
        
        if let preferredOptions = try? vImage_Buffer.preferredAlignmentAndRowBytes(width: Int(image.width), height: Int(image.width), bitsPerPixel: bitsPerPixel) {
            rowBytes = preferredOptions.rowBytes
            size = preferredOptions.rowBytes * Int(image.height)
            alignment = preferredOptions.alignment
        }
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        self.image = vImage_Buffer(data: pointer, height: image.height, width: image.width, rowBytes: rowBytes)
    }
    
    deinit {
        self.image.free()
    }
}
