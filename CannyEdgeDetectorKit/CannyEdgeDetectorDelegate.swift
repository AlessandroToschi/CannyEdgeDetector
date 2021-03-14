//
//  CannyEdgeDetectorDelegate.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 14/03/2021.
//

import Foundation

public protocol CannyEdgeDetectorDelegate: class{
    func ouputHandler(image: CGImage)
}
