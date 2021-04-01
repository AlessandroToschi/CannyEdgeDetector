//
//  CGDetector.swift
//  CannyEdgeDetector
//
//  Created by Alessandro Toschi on 08/02/2021.
//

import Foundation

public class CGDetector{
    var image: CGImage
    
    public init(image: CGImage){
        self.image = image
    }
    
    public func compute() -> CGImage?{
        guard let grayColorSpace = CGColorSpace(name: CGColorSpace.linearGray),
              let grayContext = CGContext(data: nil,
                width: self.image.width,
                height: self.image.height,
                bitsPerComponent: 32,
                bytesPerRow:  4 * self.image.width * grayColorSpace.numberOfComponents,
                space: grayColorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
                    .union(.floatComponents).rawValue),
              let grayData = grayContext.data,
              let imageData = CFDataGetBytePtr(self.image.dataProvider?.data)
        else{
            return nil
        }
        
        for row in 0..<self.image.height{
            for column in 0..<self.image.width{
                let offset = (row * self.image.bytesPerRow) + column * 4
                let r = (imageData + offset).pointee
                let g = (imageData + offset + 1).pointee
                let b = (imageData + offset + 2).pointee
                let grayValue = 0.2126 * gammaCorrection(r) + 0.7152 * gammaCorrection(g) + 0.0722 * gammaCorrection(b)
                grayData.storeBytes(of: grayValue.bitPattern.byteSwapped, toByteOffset: row * self.image.bytesPerRow + column * 4, as: UInt32.self)
            }
        }
        //grayContext.draw(self.image, in: CGRect(x: 0, y: 0, width: self.image.width, height: self.image.height))

        return grayContext.makeImage()
    }
    
    func gammaCorrection(_ pixelValue: UInt8) -> Float{
        let pixelFloatValue = Float(pixelValue) / 255.0
        if pixelFloatValue <= 0.04045{
            return pixelFloatValue / 12.92
        }else{
            return powf((pixelFloatValue + 0.055) / 1.055, 2.4)
        }
    }
}
