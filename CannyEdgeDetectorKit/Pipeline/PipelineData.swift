//
//  PipelineData.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import Foundation
import Accelerate
import CoreGraphics

enum PipelineData{
    case floatBuffer([Float])
    case vimageBuffer(VImageBufferWrapper)
    case image(CGImage)
    case any(Any)
    
    func associatedValue<T>(type: T.Type) -> T?{
        switch self{
        case .floatBuffer(let floatBuffer):
            return floatBuffer as? T
        case .vimageBuffer(let vimageBuffer):
            return vimageBuffer as? T
        case .image(let image):
            return image as? T
        case .any(let any):
            return any as? T
        }
    }
}
