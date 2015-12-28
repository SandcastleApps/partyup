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

func something(index: Int)(status: Bool, message: String)(boo: Double) -> String {
    return "\(index) \(status) \(message) \(boo)"
}

let specificSomething = something(42)
print(specificSomething(status: true, message: "hi"), terminator: "\n")
print(specificSomething(status: false, message: "bye")(boo: 3.5), terminator: "\n")

func indirectSomething(message: String, back: (Double) -> String) -> String {
    return "Indirect: \(back(5.0))"
}

print(indirectSomething("Howdy", back: specificSomething(status: true, message: "bark")), terminator: "\n")

class One {
    var num = 0
    
    func thumb(un: Int, du: Int) -> Int {
        return num + (un * du)
    }
    
    func finger(tre: Int)(qu: Int) -> (Int, Int) {
        return (num * tre - qu, num / tre + qu)
    }
}

func indirectOne(numb: (Int, Int) -> Int) -> Int {
    return numb(5, 4)
}

let one = One()
one.num = 40

print("\(indirectOne(one.thumb))")

let fi = one.finger(42)
let (a,b) = fi(qu: 4)
print("\(a) and \(b)", terminator: "\n")
let fii = One.finger(one)(54)
let (c,d) = fii(qu: 5)
print("\(c) and \(d)", terminator: "\n")

