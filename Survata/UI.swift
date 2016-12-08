//
//  UI.swift
//  Survata
//
//  Created by Rex Sheng on 2/23/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import UIKit

extension UIView {
	func alignTo(attribute: NSLayoutAttribute, margin: CGFloat = 0) {
		superview!.addConstraint(NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .Equal, toItem: superview!, attribute: attribute, multiplier: 1, constant: margin))
	}

	func fixAttribute(attribute: NSLayoutAttribute, value: CGFloat) {
		addConstraint(NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: value))
	}

	func toTheTop(margin: CGFloat = 0) {
		alignTo(.Top, margin: margin)
	}
	func toTheBottom(margin: CGFloat = 0) {
		alignTo(.Bottom, margin: -margin)
	}

	func toTheRight(margin: CGFloat = 0) {
		alignTo(.Trailing, margin: -margin)
	}

	func fullWidth(margin: CGFloat = 0) {
		alignTo(.Leading, margin: margin)
		toTheRight(margin)
	}

	func fullHeight(margin: CGFloat = 0) {
		toTheTop(margin)
		toTheBottom(margin)
	}
}

extension UIViewController {
	func fullWidth(subview: UIView, margin: CGFloat = 0) {
		subview.fullWidth(margin)
	}

	func fullHeight(subview: UIView, margin: CGFloat = 0) {
		view.addConstraint(NSLayoutConstraint(item: subview, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: margin))
		view.addConstraint(NSLayoutConstraint(item: subview, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: -margin))
	}
}

class CloseButton: UIControl {
	override func drawRect(rect: CGRect) {
		let fillColor = UIColor(white: 0.65, alpha: 1)
		let bezierPath = UIBezierPath()
		bezierPath.moveToPoint(CGPointMake(99.5, 12.54))
		bezierPath.addLineToPoint(CGPointMake(86.46, -0.5))
		bezierPath.addLineToPoint(CGPointMake(49.5, 36.46))
		bezierPath.addLineToPoint(CGPointMake(12.54, -0.5))
		bezierPath.addLineToPoint(CGPointMake(-0.5, 12.54))
		bezierPath.addLineToPoint(CGPointMake(36.46, 49.5))
		bezierPath.addLineToPoint(CGPointMake(-0.5, 86.46))
		bezierPath.addLineToPoint(CGPointMake(12.54, 99.5))
		bezierPath.addLineToPoint(CGPointMake(49.5, 62.54))
		bezierPath.addLineToPoint(CGPointMake(86.46, 99.5))
		bezierPath.addLineToPoint(CGPointMake(99.5, 86.46))
		bezierPath.addLineToPoint(CGPointMake(62.54, 49.5))
		bezierPath.addLineToPoint(CGPointMake(99.5, 12.54))
		bezierPath.closePath()
		if let context = UIGraphicsGetCurrentContext() {
            CGContextSaveGState(context)
            
            let width: CGFloat = 15
            let height: CGFloat = 15
            let scale: CGFloat = 0.15
            CGContextTranslateCTM(context, (rect.size.width - width) / 2, (rect.size.height - height) / 2)
            CGContextScaleCTM(context, scale, scale)
            fillColor.setFill()
            bezierPath.fill()
            CGContextRestoreGState(context)
        }
	}
}
