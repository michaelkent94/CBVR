//
//  Tracker.swift
//  CBVR
//
//  Created by Michael Kent on 2/17/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import UIKit

public struct Color: Equatable, Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    
    public var hashValue: Int {
        return (Int(r) << 16) | (Int(g) << 8) | Int(b)
    }
    
    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

public func ==(lhs: Color, rhs: Color) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public class Tracker {
    
    public var colors = [Color]()
    public var centersByColor = [Color: CGPoint]()
    public var threshold = 10 as Int
    
    public func process(image image: CGImage) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = CGImageGetWidth(image)
        let height = CGImageGetHeight(image)
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue
        
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image)
        
        let pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(context))
        
        var currentPixel = pixelBuffer
        
        let threshold2 = threshold * threshold
        
        var sumsByColor = [Color: (x: Float, y: Float)]()
        var countsByColor = [Color: Int]()

        for y in 0..<height {
            for x in 0..<width {
                let currentColorValue = currentPixel.memory
                let r = red(currentColorValue)
                let g = green(currentColorValue)
                let b = blue(currentColorValue)
                
                for color in colors {
                    let diffR = Int(r) - Int(color.r)
                    let diffG = Int(g) - Int(color.g)
                    let diffB = Int(b) - Int(color.b)
                    let distance2 = diffR * diffR + diffG * diffG + diffB * diffB
                    if distance2 <= threshold2 {
                        if let sum = sumsByColor[color] {
                            sumsByColor[color] = (sum.x + Float(x), sum.y + Float(y))
                            countsByColor[color]!++
                        } else {
                            sumsByColor[color] = (Float(x), Float(y))
                            countsByColor[color] = 1
                        }
                        break
                    }
                }
                
                currentPixel++
            }
        }
        
        for (color, sum) in sumsByColor {
            let count = CGFloat(countsByColor[color]!)
            let average = CGPoint(x: CGFloat(sum.x) / count, y: CGFloat(sum.y) / count)
            centersByColor[color] = average
        }
    }
}

func red(color: UInt32) -> UInt8 {
    return UInt8(color & 255)
}

func green(color: UInt32) -> UInt8 {
    return UInt8((color >> 8) & 255)
}

func blue(color: UInt32) -> UInt8 {
    return UInt8((color >> 16) & 255)
}

func alpha(color: UInt32) -> UInt8 {
    return UInt8((color >> 24) & 255)
}

func rgba(red red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UInt32 {
    return UInt32(red) | (UInt32(green) << 8) | (UInt32(blue) << 16) | (UInt32(alpha) << 24)
}
