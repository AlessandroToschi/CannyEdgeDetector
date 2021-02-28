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
    
    init(image: vImage_Buffer){
        self.image = image
    }
    
    deinit {
        print("deinit")
        self.image.free()
    }
}
