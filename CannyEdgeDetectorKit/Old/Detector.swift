//
//  Detector.swift
//  CannyEdgeDetectorKit
//
//  Created by Alessandro Toschi on 15/02/2021.
//

import Foundation

public protocol Detector{
    //var image: CGImage{get set}
    func setup() -> Bool
    func compute(image: CGImage) -> CGImage?
}
