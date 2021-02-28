//
//  ViewController.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 08/02/2021.
//

import Cocoa
import CannyEdgeDetectorKit

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = Image(contentsOfFile: "/Users/alessandro/Downloads/BSR/BSDS500/data/images/test/10081.jpg"){
            self.imageView.image = image
        }
    }

    @IBAction func detect(_ sender: Any) {
        if let cgImage = self.imageView.image?.cgImage{
            let detector = AccelerateDetector()
            let startTime = DispatchTime.now()
            if let grayImage = detector.compute(image: cgImage){
                self.imageView.image = Image(cgImage: grayImage, size: NSSize(width: grayImage.width, height: grayImage.height))
                /*
                if let grayImageData = grayImage.dataProvider?.data as Data?{
                    try? grayImageData.write(to: URL(fileURLWithPath: "/Users/alessandro/Desktop/OS X/colors/mygray32bpp32bpc.bin"))
                }
 
                print(grayImage.byteOrderInfo.rawValue)
                */
            }
            let endTime = DispatchTime.now()
            let elapsed = (endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            print("\(elapsed) ms")
            
        }
    }
    
}

