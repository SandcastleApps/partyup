//: Playground - noun: a place where people can play

//import UIKit
//import QuartzCore

//class ProgressArc: UIView
//{
//	override init(frame: CGRect) {
//		super.init(frame: frame)
//
//		let shapeLayer = layer as! CAShapeLayer
//		shapeLayer.path = UIBezierPath(arcCenter: self.center, radius: self.frame.size.width / 2 * 0.83, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true).CGPath
//		shapeLayer.fillColor = UIColor.clearColor().CGColor
//		shapeLayer.strokeColor = UIColor.redColor().CGColor
//		shapeLayer.lineWidth = 4
//		shapeLayer.strokeStart = 0
//		shapeLayer.strokeEnd = 0.83
//	}
//
//	required init?(coder aDecoder: NSCoder) {
//	    super.init(coder: aDecoder)
//
//		let shapeLayer = layer as! CAShapeLayer
//		shapeLayer.path = UIBezierPath(arcCenter: self.center, radius: self.frame.size.height / 2, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true).CGPath
//
//		shapeLayer.strokeStart = 0
//		shapeLayer.strokeEnd = 0
//	}
//
//	override class func layerClass() -> AnyClass {
//		return CAShapeLayer.self
//	}
//
//	func setProgress(progress: Float) {
//		let shapeLayer = layer as! CAShapeLayer
//		shapeLayer.strokeStart = 0.0
//		shapeLayer.strokeEnd = CGFloat(progress)
//	}
//}
//
//var viewport = ProgressArc(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//viewport.setProgress(0.5)
//viewport.tintColor = UIColor.redColor()


