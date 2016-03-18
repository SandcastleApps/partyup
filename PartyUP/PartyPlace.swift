//
//  PartyPlace.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-06.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import CoreLocation
import LMGeocoder
import Alamofire
import SwiftyJSON
import Flurry_iOS_SDK

class PartyPlace : FetchQueryable {
	static let CityUpdateNotification = "CityUpdateNotification"
    static let CityUpdateThrottlingInterval = 86400.0

	let place: LMAddress
	let pregame: Venue
	var venues = Set<Venue>() {
		didSet {
			NSNotificationCenter.defaultCenter().postNotificationName(PartyPlace.CityUpdateNotification, object: self)
		}
	}

	var ads: [Advertisement] {
		return Advertisement.apropos(place.locality, ofFeed: .All) ?? []
	}

	private(set) var lastFetchStatus = FetchStatus(completed: NSDate(timeIntervalSince1970: 0), error: nil)
	private(set) var isFetching = false

	private static let placesKey = "***REMOVED***"

	init(place: LMAddress) {
		self.place = place
		let unique = String(format: "*%@$%@$%@*", place.locality, place.administrativeArea, place.country)
		let name = place.locality + " " + NSLocalizedString("Pregame Feed", comment: "Place name suffix for pregame venue")
		self.pregame = Venue(unique: unique, open: 0, close: 0, name: name, details: nil, vicinity: place.administrativeArea, location: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))

		Advertisement.fetch(place)
	}

	func fetch(radius: Int, categories: String) {
		if abs(lastFetchStatus.completed.timeIntervalSinceNow) > PartyPlace.CityUpdateThrottlingInterval || lastFetchStatus.error != nil  {
			if !isFetching {
				isFetching = true
				let params = ["location" : "\(place.coordinate.latitude),\(place.coordinate.longitude)",
					"types" : categories,
					"rankby" : "distance",
					"key" : PartyPlace.placesKey]
				Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: params)
					.validate()
					.responseJSON { response in
						self.grokResponse(response)
				}
			}
		} else {
			let stale = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval)
			let suppress = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.SampleSuppressionThreshold)
			venues.forEach { $0.fetchSamples(withStaleInterval: stale, andSuppression: suppress); $0.fetchPromotion() }
			pregame.fetchSamples(withStaleInterval: stale, andSuppression: suppress)
            NSNotificationCenter.defaultCenter().postNotificationName(PartyPlace.CityUpdateNotification, object: self)
		}
	}

	func grokResponse(response: Response<AnyObject, NSError>) -> Void {
		if response.result.isSuccess {
			let json = JSON(data: response.data!)
            let local = json["results"].arrayValue.map{Venue(venue: $0)}
            
            dispatch_async(dispatch_get_main_queue()) { self.venues.unionInPlace(local) }

			if let next = json["next_page_token"].string {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
					Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: ["pagetoken" : next, "key" : PartyPlace.placesKey])
						.validate()
						.responseJSON { response in
							self.grokResponse(response)
					}
				}
			} else {
				isFetching = false
				lastFetchStatus = FetchStatus(completed: NSDate(), error: nil)
			}
		} else {
			isFetching = false
			lastFetchStatus = FetchStatus(completed: NSDate(), response.result.error)
			Flurry.logError("Venue_Query_Failed", message: "\(response.description)", error: response.result.error)
		}
	}
}
