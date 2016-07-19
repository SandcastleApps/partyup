//
//  Seedling.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-07-02.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import CoreLocation
import SwiftDate
import SwiftyJSON
import Alamofire

extension Venue {
	func fetchSeedlings() {
		if let token = FBSDKAccessToken.currentAccessToken() {
			Alamofire.request(.GET,
				"https://graph.facebook.com/v2.7/search", parameters: ["q":name,"type":"place","center":"\(location.coordinate.latitude),\(location.coordinate.longitude)","distance":"\(100)","fields":"link","access_token":token.tokenString]).responseJSON { response in
					switch response.result {
					case .Success(let data):
						let places = JSON(data)
						if let id = places["data"][0]["id"].string {
							Alamofire.request(.GET,
								"https://graph.facebook.com/v2.7/\(id)", parameters: ["fields":"video_broadcasts{video{source,description,from,updated_time}}","access_token":token.tokenString]).responseJSON(queue: dispatch_get_main_queue()) { response in
									var seeders = [Seedling]()
									switch response.result {
									case .Success(let data):
										let page = JSON(data)
										for cast in page["video_broadcasts"]["data"].arrayValue {
											let video = cast["video"]
												guard let source = video["source"].string.flatMap({ NSURL(string: $0) }),
													let time = video["updated_time"].string.flatMap({ $0.toDate(DateFormat.ISO8601) }) else { continue }
												let comment = video["description"].string
												let alias = video["from"]["name"].string
												seeders.append(Seedling(user: NSUUID(), alias: alias, event: self, time: time, comment: comment, media: source, via: "Facebook"))
											}

									case .Failure(let error):
										print("Error fetching movies: \(error)")
									}

									self.seeds = seeders
							}
                        } else {
                            self.seeds = [Seedling]()
                        }
					case .Failure(let error):
						print("Error fetching places: \(error)")
						self.seeds = [Seedling]()
					}
			}
		} else {
			self.seeds = [Seedling]()
		}
	}
}

class Seedling: Tastable {
	let user: NSUUID
	let alias: String?
	unowned let event: Venue
	let time: NSDate
	let comment: String?
	let media: NSURL
    let via: String

    init(user: NSUUID, alias: String?, event: Venue, time: NSDate, comment: String?, media: NSURL, via: String = "Facebook") {
		self.user = user
		self.alias = alias
		self.event = event
		self.time = time
		self.comment = comment
		self.media = media
        self.via = via
	}
}

