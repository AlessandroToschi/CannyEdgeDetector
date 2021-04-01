//
//  TemporaryBuffer.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 28/02/2021.
//

import Foundation

class TemporaryBuffer{
    private(set) var buffer: UnsafeMutableRawPointer
    private(set) var count: Int
    
    convenience init(){
        self.init(count: 0)
    }
    
    init(count: Int) {
        self.buffer = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
        self.count = count
    }
    
    deinit {
        self.buffer.deallocate()
    }
    
    func reallocIfNeeded(newSize: Int){
        if newSize > self.count{
            self.realloc(newSize: newSize)
        }
    }
    
    func realloc(newSize: Int){
        self.buffer.deallocate()
        self.buffer = UnsafeMutableRawPointer.allocate(byteCount: newSize, alignment: 1)
        self.count = newSize
    }
}
