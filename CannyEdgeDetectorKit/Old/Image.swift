#if os(iOS)
import UIKit
public typealias Image = UIImage
#elseif os(OSX)
import AppKit
public typealias Image = NSImage
#endif

extension Image{
    public var cgImage: CGImage?{
        #if os(iOS)
        return self.cgImage
        #elseif os(OSX)
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }
}
