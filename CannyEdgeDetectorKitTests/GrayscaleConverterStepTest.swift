//
//  GrayscaleConverterStepTest.swift
//  CannyEdgeDetectorKitTests
//
//  Created by Alessandro Toschi on 20/02/2021.
//

import XCTest
import CoreGraphics
@testable import CannyEdgeDetectorKit

class GrayscaleConverterStepTest: XCTestCase {
    
    func testGrayscaleConverterStep(){
        let testBundle = Bundle(for: type(of: self))
        guard let filePath = testBundle.path(forResource: "10081", ofType: "jpg"),
              let image = NSImage(byReferencingFile: filePath)?.cgImage
        else{
            XCTFail()
            return
        }
        
        let pipeline = Pipeline()
        pipeline.addStep(step: GrayscaleConverterStep())
        XCTAssertNoThrow(try pipeline.execute(input: .image(image)))
        XCTAssertNoThrow(try pipeline.execute(input: .image(image)))
    }
}
