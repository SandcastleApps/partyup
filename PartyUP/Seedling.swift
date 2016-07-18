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
                            FBSDKGraphRequest(graphPath: "/\(id)", parameters: ["fields":"video_broadcasts{video{source,description,from,updated_time}}"]).startWithCompletionHandler {
                                (connection, page, error) in
                                var seeders = [Seedling]()
                                if let broadcasts = page["video_broadcasts"] as? [String:AnyObject], let videos = broadcasts["data"] as? [AnyObject] {
                                    for video in videos {
                                        if let item = video["video"] as? [String:AnyObject]{
                                            guard let source = (item["source"] as? String).flatMap({NSURL(string: $0)}),
                                                let time = (item["updated_time"] as? String).flatMap({$0.toDate(DateFormat.ISO8601)})  else { continue }
                                            let comment = item["description"] as? String
                                            let alias = (item["from"] as? [String:AnyObject])?["name"] as? String
                                            seeders.append(Seedling(user: NSUUID(), alias: alias, event: self, time: time, comment: comment, media: source, via: "Facebook"))
                                        }
                                    }
                                }
                            
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.seeds = seeders
                                }
                            }
                        }
                    case .Failure(let error):
                        print("Error fetching places: \(error)")
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

