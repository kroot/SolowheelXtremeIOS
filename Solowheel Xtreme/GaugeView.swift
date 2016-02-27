//
//  GaugeView.swift
//  Solowheel Xtreme
//
//  Created by kroot on 10/16/15.
//

import Foundation
import UIKit

extension CGFloat {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

class GaugeView : UIView
{
    
    let redColor = UIColor.redColor().CGColor
    let blackColor = UIColor.blackColor().CGColor

    var percent = Int(0)
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        setupUI()
    }
    
    func setupUI() {

    }
    
    internal func setGaugeValue(percent: Int) {
        if percent >= 0 && percent <= 100 {
            self.percent = percent
            
            self.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {

        let context = UIGraphicsGetCurrentContext()
        
        let width = Int(rect.width)
        let height = Int(rect.height)
        var x:Int = 0
        var y:Int = 0
        var size:Int = width
        
        // maintain aspect ratio
        if (height > width) {
            size = width
            y = Int(height - width)
        }
        else {
            size = height
            x = Int(width - height)
        }
        
        let containerRect = CGRect(x:x, y:y, width:size, height:size)
        
        drawLedSegments(context!, containerRect: containerRect, segmentAngle: 0.0)
    }
    
    
    func drawLedSegments(context: CGContext, containerRect: CGRect, segmentAngle: CGFloat)
    {
        let numSegments = 100
        let segmentArcSpan = CGFloat(270).degreesToRadians / 100

        CGContextSaveGState(context)

        CGContextSetStrokeColorWithColor(context, blackColor)
        CGContextStrokePath(context)

        
        let outerRadius = Int(containerRect.width / 2)

        let scale = 1.0 / Double(numSegments)
        
        var alpha: CGFloat
        
        for stepNum in (0 ..< numSegments).reverse() {
            let segmentPath = getLedSegmentPath(context, containerRect: containerRect)

            CGContextSaveGState(context)

            let centerY = containerRect.origin.y / 2
            CGContextTranslateCTM( context, CGFloat(outerRadius), CGFloat(centerY) + CGFloat(outerRadius))

            CGContextRotateCTM(context, CGFloat(stepNum) * -segmentArcSpan)
            
            if numSegments - stepNum > self.percent
            {
                alpha = 0.1
            }
            else
            {
                alpha = 1.0
            }
            let red = CGFloat((Double(stepNum) * scale))
            let green = CGFloat(1.0 - (Double(stepNum) * scale))
            let blue = CGFloat(0)
            
            let rgb = UIColor(red: red, green: green, blue: blue, alpha: alpha)

            CGContextSetAlpha(context, 1.0)

            CGContextSetFillColorWithColor(context, rgb.CGColor)
            
            segmentPath.closePath()

            segmentPath.fill()

            segmentPath.stroke()

            CGContextRestoreGState(context)
        }
        
        CGContextRestoreGState(context)
    }
    
    func getLedSegmentPath(context: CGContext, containerRect: CGRect) -> UIBezierPath {
        
        let segmentArcSpan = CGFloat(270).degreesToRadians / 100
        
        let segmentWidth = Int(containerRect.height / 10)

        
        let outerRadius = Int(containerRect.width / 2)
        let innerRadius = outerRadius - segmentWidth
        
        let segmentArcRad2 = segmentArcSpan / 2
        
        let drawingCenter = CGPoint(x:0, y:0)
        
        let path = UIBezierPath(arcCenter: drawingCenter, radius: CGFloat(innerRadius), startAngle: -segmentArcRad2, endAngle: segmentArcRad2, clockwise: true)
        
        path.addArcWithCenter(drawingCenter, radius: CGFloat(outerRadius), startAngle: segmentArcRad2, endAngle: -segmentArcRad2, clockwise: false)
        
        //path.closePath()
        path.lineWidth = 1.0
     
        return path
    }
}