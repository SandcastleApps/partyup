//
//  PartyPlace.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-06.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON
import Flurry_iOS_SDK

class PartyPlace {
	let place: CLPlacemark
	let sticky: Bool
	var venues: [Venue]?

	init(place: CLPlacemark, sticky: Bool = true) {
		self.place = place
		self.sticky = sticky
	}

	func fetch(radius: Int, categories: String, completion: (Bool) -> Void) {
		if let loc = place.location {
			let params = ["location" : "\(loc.coordinate.latitude),\(loc.coordinate.longitude)",
				"radius" : "\(radius)",
				"types" : "bar",
				"key" : "***REMOVED***"]

			Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: params)
				.validate()
				.responseJSON(PartyPlace.grokResponse(self)([Venue](), completion: completion))
		}
	}

	func grokResponse(var aquired: [Venue], completion: (Bool) -> Void)(response: Response<AnyObject, NSError>) -> Void {
		if response.result.isSuccess {
			let json = JSON(data: response.data!)
			for venue in json["results"].arrayValue {
				aquired.append(Venue(venue: venue))
			}

			if let next = json["next_page_token"].string {
				Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: ["pagetoken" : next, "key" : "***REMOVED***"])
					.validate()
					.responseJSON(PartyPlace.grokResponse(self)(aquired, completion: completion))
			} else {
				if let loc = self.place.location {
					self.venues = aquired.sort { $0.location.distanceFromLocation(loc) < $1.location.distanceFromLocation(loc) }
				}
				completion(true)
			}
		} else {
			completion(false)
			Flurry.logError("Venue_Query_Failed", message: "\(response.description)", error: nil)
		}
	}
}
