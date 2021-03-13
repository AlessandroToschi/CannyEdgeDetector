//
//  LiveView.swift
//  CannyViewer
//
//  Created by Alessandro Toschi on 09/03/2021.
//

import Cocoa

class LiveView: NSView, CALayerDelegate{
    var image: CGImage?{
        didSet{
            self.needsDisplay = true
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer?.delegate = self
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func display(_ layer: CALayer) {
        guard let image = self.image else {return}
        layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: -1.0, b: 0.0, c: 0.0, d: 1.0, tx: layer.frame.width, ty: 0.0))
        layer.contents = image
    }
}
