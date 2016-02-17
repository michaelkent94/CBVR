//
//  CBVRTests.swift
//  CBVRTests
//
//  Created by Michael Kent on 1/15/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import XCTest
@testable import CBVR

class CBVRTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testTrackerProcess() {
        let width = 100 as Int
        let height = 100 as Int
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        CGContextSetRGBFillColor(context, 255, 0, 0, 1)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: width, height: height))
        
        let image = CGBitmapContextCreateImage(context)!
        
        let tracker = Tracker()
        let color = Color(r: 255, g: 0, b: 0)
        tracker.colors.append(color)
        tracker.process(image: image)
        let x = tracker.centersByColor[color]!.x
        let y = tracker.centersByColor[color]!.y
        XCTAssert(x >= 49.5 && x <= 50.5 && y >= 49.5 && y <= 50.5, "Center not in correct location")
    }
    
}
