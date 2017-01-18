//
//  UI.swift
//  Survata
//
//  Created by Rex Sheng on 2/23/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import UIKit

extension UIView {
	func alignTo(_ attribute: NSLayoutAttribute, margin: CGFloat = 0) {
		superview!.addConstraint(NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: superview!, attribute: attribute, multiplier: 1, constant: margin))
	}

	func fixAttribute(_ attribute: NSLayoutAttribute, value: CGFloat) {
		addConstraint(NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: value))
	}

	func toTheTop(_ margin: CGFloat = 0) {
		alignTo(.top, margin: margin)
	}
	func toTheBottom(_ margin: CGFloat = 0) {
		alignTo(.bottom, margin: -margin)
	}

	func toTheRight(_ margin: CGFloat = 0) {
		alignTo(.trailing, margin: -margin)
	}

	func fullWidth(_ margin: CGFloat = 0) {
		alignTo(.leading, margin: margin)
		toTheRight(margin)
	}

	func fullHeight(_ margin: CGFloat = 0) {
		toTheTop(margin)
		toTheBottom(margin)
	}
}

extension UIViewController {
	func fullWidth(_ subview: UIView, margin: CGFloat = 0) {
		subview.fullWidth(margin)
	}

	func fullHeight(_ subview: UIView, margin: CGFloat = 0) {
		view.addConstraint(NSLayoutConstraint(item: subview, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: margin))
		view.addConstraint(NSLayoutConstraint(item: subview, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -margin))
	}
}

class CloseButton: UIControl {
	override func draw(_ rect: CGRect) {
		let fillColor = UIColor(white: 0.65, alpha: 1)
		let bezierPath = UIBezierPath()
		bezierPath.move(to: CGPoint(x: 99.5, y: 12.54))
		bezierPath.addLine(to: CGPoint(x: 86.46, y: -0.5))
		bezierPath.addLine(to: CGPoint(x: 49.5, y: 36.46))
		bezierPath.addLine(to: CGPoint(x: 12.54, y: -0.5))
		bezierPath.addLine(to: CGPoint(x: -0.5, y: 12.54))
		bezierPath.addLine(to: CGPoint(x: 36.46, y: 49.5))
		bezierPath.addLine(to: CGPoint(x: -0.5, y: 86.46))
		bezierPath.addLine(to: CGPoint(x: 12.54, y: 99.5))
		bezierPath.addLine(to: CGPoint(x: 49.5, y: 62.54))
		bezierPath.addLine(to: CGPoint(x: 86.46, y: 99.5))
		bezierPath.addLine(to: CGPoint(x: 99.5, y: 86.46))
		bezierPath.addLine(to: CGPoint(x: 62.54, y: 49.5))
		bezierPath.addLine(to: CGPoint(x: 99.5, y: 12.54))
		bezierPath.close()
		if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            
            let width: CGFloat = 15
            let height: CGFloat = 15
            let scale: CGFloat = 0.15
            context.translateBy(x: (rect.size.width - width) / 2, y: (rect.size.height - height) / 2)
            context.scaleBy(x: scale, y: scale)
            fillColor.setFill()
            bezierPath.fill()
            context.restoreGState()
        }
	}
}
