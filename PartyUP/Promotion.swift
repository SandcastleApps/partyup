//
//  Promotion.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-01-12.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import AWSDynamoDB

final class Promotion: CustomDebugStringConvertible, Equatable
{
    unowned let venue: Venue
    let placement: Int
    let tagline: String?
    
    init(venue: Venue, placement: Int = 0, tagline: String? = nil) {
        self.venue = venue
        self.placement = placement
        self.tagline = tagline
    }
    
    var debugDescription: String {
        get { return "Placement = \(placement)\nTagline = \(tagline)\n" }
    }
    
    //MARK - Internal Dynamo Representation
    
	internal convenience init(data: PromotionDB, venue: Venue) {
        self.init(
            venue: venue,
            placement: data.placement?.integerValue ?? 0,
            tagline: data.tagline as String?
        )
    }
    
    internal var dynamo: PromotionDB {
        get {
            let db = PromotionDB()
            db.venue = venue.unique
            db.placement = placement
            db.tagline = tagline
            
            return db
        }
    }
    
    internal class PromotionDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling
    {
        var venue: NSString?
        var placement: NSNumber?
        var tagline: NSString?
        
        @objc static func dynamoDBTableName() -> String {
            return "Promotions"
        }
        
        @objc static func hashKeyAttribute() -> String! {
            return "venue"
        }
    }
}

func ==(lhs: Promotion, rhs: Promotion) -> Bool {
	return (lhs.placement == rhs.placement) && (lhs.tagline == rhs.tagline)
}

