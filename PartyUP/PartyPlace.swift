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
	var venues: [Venue]?

	private static let placesKey = "***REMOVED***"

	init(place: CLPlacemark) {
		self.place = place
	}

	func fetch(radius: Int, categories: String, completion: (Bool, Bool) -> Void) {
		if venues == nil {
			if let loc = place.location {
				venues = [Venue]()
				let params = ["location" : "\(loc.coordinate.latitude),\(loc.coordinate.longitude)",
					"types" : categories,
					"rankby" : "distance",
					"key" : PartyPlace.placesKey]
				Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: params)
					.validate()
					.responseJSON { response in
						self.grokResponse(completion, response: response)
				}
			}
		} else {
			completion(true, false)
		}
	}

	func grokResponse(completion: (Bool, Bool) -> Void, response: Response<AnyObject, NSError>) -> Void {
		if response.result.isSuccess {
			let json = JSON(data: response.data!)
			for venue in json["results"].arrayValue {
				venues!.append(Venue(venue: venue))
			}

			if let next = json["next_page_token"].string {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
					Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: ["pagetoken" : next, "key" : PartyPlace.placesKey])
						.validate()
						.responseJSON { response in
							self.grokResponse(completion, response: response)
					}
				}
				completion(true, true)
			} else {
				completion(true, false)
			}
		} else {
			if let vens = venues where vens.isEmpty {
				venues = nil
			}
			completion(false, false)
			Flurry.logError("Venue_Query_Failed", message: "\(response.description)", error: nil)
		}
	}
}
