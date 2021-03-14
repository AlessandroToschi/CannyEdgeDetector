//
//  DetectorStrategy.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 13/03/2021.
//

import Foundation
import AVFoundation
import CoreGraphics
import Accelerate

public protocol DetectorStrategy{
    var outputFormat: vImage_CGImageFormat { get set }
    
    func detect(_ imageBuffer: CVPixelBuffer) throws -> CGImage?
    func detect(_ image: CGImage) throws -> CGImage?
}

extension DetectorStrategy{
    public func detect(_ imageBuffer: CVPixelBuffer) throws -> CGImage?{
        return nil
    }
    
    public func detect(_ image: CGImage) throws -> CGImage?{
        return nil
    }
}
