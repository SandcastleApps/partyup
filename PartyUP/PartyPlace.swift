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
			let params = ["ll" : "\(loc.coordinate.latitude),\(loc.coordinate.longitude)",
				"radius" : "\(radius)",
				"client_id" : FourSquareConstants.identifier,
				"client_secret" : FourSquareConstants.secret,
				"categoryId" : categories,
				"v" : "20140118",
				"intent" : "browse",
				"limit" : "50"]

			Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/search", parameters: params)
				.validate()
				.responseJSON { response in
					if response.result.isSuccess {
						var vens = [Venue]()
						let json = JSON(data: response.data!)
						for venue in json["response"]["venues"].arrayValue {
							vens.append(Venue(venue: venue))
						}
						self.venues = vens.sort { $0.location.distanceFromLocation(loc) < $1.location.distanceFromLocation(loc) }
					} else {
						Flurry.logError("Venue_Query_Failed", message: "\(response.description)", error: nil)

					}

					completion(response.result.isSuccess)
			}
		}
	}
}
