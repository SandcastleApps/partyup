//: Playground - noun: a place where people can play

import UIKit
import Foundation

protocol Dippy
{
	typealias DippyInternal
	typealias DippyKey

	init(high: Int)

	var dippyDoo: DippyInternal { get}
}

class Outer: Dippy
{
	var high: Int

	required init(high: Int = 90)
	{
		self.high = high
	}

	typealias DippyInternal = OuterRep
	typealias DippyKey = NSNumber

	var dippyDoo: OuterRep { return OuterRep(priority: 3) }

	class OuterRep
	{
		var time: NSDate
		var priority: Int

		init(time: NSDate = NSDate(), priority: Int = 0) {
			self.time = time
			self.priority = priority
		}
	}
}

func done<T: Dippy where T.DippyKey == NSObject>(key: T.DippyKey, go: ([T]) -> Void) {
	let something: AnyObject! = key

	let outers = [T(high: 23), T(high: 24)]

	go(outers)
}

done(4) { (test: [Outer]) in print("Array: \(test)") }
