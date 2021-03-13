//
//  CMDimensionsExtension.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 07/03/2021.
//

import Foundation
import AVFoundation

extension CMVideoDimensions: Equatable{
    public static func ==(lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool{
        return lhs.height == rhs.height && lhs.width == rhs.width
    }
}
