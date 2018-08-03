//
//  UIImage+Additions.swift
//  Quick Maths
//
//  Created by Kevin Tan on 7/31/18.
//  Copyright © 2018 KxTGames. All rights reserved.
//

import UIKit

extension UIImage {
    func scaled(by factor: CGFloat) -> UIImage? {
        let tw = size.width * factor
        let th = size.height * factor
        let targetSize = CGSize(width: tw, height: th)

        UIGraphicsBeginImageContext(targetSize)
        draw(in: CGRect(origin: CGPoint.zero, size: targetSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    func getPixelAlpha(at position: CGPoint) -> CGFloat {
        guard let image = cgImage else { return 0 }

        let pixelData = image.dataProvider?.data
        let pixelInfo = (Int(image.width) * Int(position.y) + Int(position.x)) * 4

        if let data = CFDataGetBytePtr(pixelData) {
            return CGFloat(data[pixelInfo + 3]) / 255
        } else {
            print("could not get pixel alpha")
            return 0
        }
    }

    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return pixelData
    }
}
