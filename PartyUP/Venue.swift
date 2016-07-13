//
//  Venue.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import SwiftyJSON
import CoreLocation
import AWSDynamoDB
import FBSDKCoreKit

final class Venue: Hashable, CustomDebugStringConvertible, FetchQueryable
{
	static let VitalityUpdateNotification = "VitalityUpdateNotification"
	static let PromotionUpdateNotification = "PromotionUpdateNotification"

	let unique: String
	let open: NSTimeInterval
	let close: NSTimeInterval
	let name: String
	let details: String?
	let location: CLLocation
	var promotion: Promotion? {
		didSet {
			if promotion != oldValue {
				NSNotificationCenter.defaultCenter().postNotificationName(Venue.PromotionUpdateNotification, object: self, userInfo: oldValue != nil ?["old" : oldValue!] : nil)
			}
		}
	}
    
	var seeds: [Seedling]? {
		didSet {
			done(delta: (seeds?.count ?? 0) - (oldValue?.count ?? 0))
		}
	}

    var treats: [Tastable]? {
        guard let real = samples, let fake = seeds else { return nil }
        return real.map({ $0 as Tastable }) + fake.map({ $0 as Tastable})
    }

	var samples: [Sample]? {
		didSet {
			done(delta: (samples?.count ?? 0) - (oldValue?.count ?? 0))
		}
	}

	private func done(delta delta: Int) {
		if samples != nil && seeds != nil {
			lastFetchStatus = FetchStatus(completed: NSDate(), error: nil)
			isFetching = false
			NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: self, userInfo: ["delta" : delta])
		}
	}

	var vitality: Int {
		get {
			return (samples?.count ?? 0) + (seeds?.count ?? 0)
		}
	}

	private(set) var lastFetchStatus = FetchStatus(completed: NSDate(timeIntervalSince1970: 0), error: nil)
	private(set) var isFetching = false

	private(set) var lastPromotionFetchStatus = FetchStatus(completed: NSDate(timeIntervalSince1970: 0), error: nil)
	private(set) var isPromotionFetching = false

	var ads: [Advertisement] {
		return Advertisement.apropos(unique, ofFeed: Advertisement.FeedCategory.Venue)
	}

	private var votings = Set<NSData>()
	private var potentials: [Sample]? {
		didSet {
			if let locals = potentials {
				if locals.isEmpty {
					samples = potentials
				} else {
					votings = Set<NSData>(locals.filter { $0.flag == nil }.map{ $0.identifier })
				}
			}
		}
	}

	init(unique: String, open: NSTimeInterval, close: NSTimeInterval, name: String, details: String?, location: CLLocation) {
		self.unique = unique
		self.open = open
		self.close = close
		self.name = name
		self.details = details
		self.location = location

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Venue.sieveOffendingSamples), name: Defensive.OffensiveMuteUpdateNotification, object: nil)

	}

	convenience init(venue: JSON) {
		self.init(
			unique: venue["place_id"].stringValue,
			open: 0,
			close: 0,
			name: venue["name"].stringValue,
			details: nil, //venue["description"].string,
			location: CLLocation(latitude: venue["geometry"]["location"]["lat"].doubleValue, longitude: venue["geometry"]["location"]["lng"].doubleValue)
		)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func fetchPromotion(withTimeliness timely: NSTimeInterval = 0) {
		if abs(lastPromotionFetchStatus.completed.timeIntervalSinceNow) > timely || lastPromotionFetchStatus.error != nil {
			if !isPromotionFetching {
				isPromotionFetching = true
				AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().load(Promotion.PromotionDB.self, hashKey: unique, rangeKey: nil).continueWithBlock{ task in
					if !task.faulted {
						if let result = task.result as? Promotion.PromotionDB where result.venue != nil {
							dispatch_async(dispatch_get_main_queue()) { self.promotion = Promotion(data: result, venue: self) }
						} else {
							self.promotion = nil
						}
					}

					self.isPromotionFetching = false
					self.lastPromotionFetchStatus = FetchStatus(completed: NSDate(), error: task.error)

					return nil
				}
			}
		}
	}

	func fetchSamples(
		withStaleInterval stale: NSTimeInterval = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval),
		andSuppression suppress: Int = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.SampleSuppressionThreshold),
		andTimeliness timely: NSTimeInterval = 0) {

			if abs(lastFetchStatus.completed.timeIntervalSinceNow) > timely || lastFetchStatus.error != nil {
				if !isFetching {
					isFetching = true
					let time = NSDate().timeIntervalSince1970 - stale
					let query = AWSDynamoDBQueryExpression()
					query.keyConditionExpression = "#u = :unique"
					query.filterExpression = "#t > :stale OR attribute_exists(#p)"
					query.expressionAttributeNames = ["#t": "time", "#p": "prefix", "#u":"event"]
					query.expressionAttributeValues = [":stale" : NSNumber(double: time), ":unique" : unique]
					AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(Sample.SampleDB.self, expression: query).continueWithBlock { (task) in
						if let result = task.result as? AWSDynamoDBPaginatedOutput {
							if let items = result.items as? [Sample.SampleDB] {
								let wraps = items.map { Sample(data: $0, event: self) }.filter { ($0.rating[0] - $0.rating[1] > suppress) && !Defensive.shared.muted($0.user) }.sort { $0.time.compare($1.time) == .OrderedDescending }
								dispatch_async(dispatch_get_main_queue()) { self.potentials = wraps }
							}
						}

						return nil
					}

					fetchSeedlings()
				}
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					NSNotificationCenter.defaultCenter().postNotificationName(Venue.VitalityUpdateNotification, object: self, userInfo: ["delta" : 0])
				}
			}
    }

	func sieveSample(sample: Sample) {
		if potentials != nil {
			votings.remove(sample.identifier)

			if sample.flag == true, let index = potentials?.indexOf(sample) {
				potentials?.removeAtIndex(index)
			}

			if votings.isEmpty {
				samples = potentials
				potentials = nil
			}
		} else {
			if sample.flag == true {
				samples = samples?.filter { $0 != sample }
			}
		}
	}
    
	@objc func sieveOffendingSamples() {
        if let filtered = samples?.filter({ !Defensive.shared.muted($0.user) }) {
            if filtered.count != samples!.count {
                samples = filtered
            }
        }
    }

	var debugDescription: String {
		get { return "Unique = \(unique)\nopen = \(open)\nclose = \(close)\nname = \(name)\ndetails = \(details)\nlocation = \(location)" }
	}

	var hashValue: Int {
		get { return unique.hashValue }
	}
}

func ==(lhs: Venue, rhs: Venue) -> Bool {
	return lhs.unique == rhs.unique
}