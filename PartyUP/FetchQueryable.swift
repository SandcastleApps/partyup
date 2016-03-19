//
//  Fetchable.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-03-17.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

typealias FetchStatus = (completed: NSDate, error: NSError?)

protocol FetchQueryable
{
	var lastFetchStatus: FetchStatus { get }
	var isFetching: Bool { get }
}