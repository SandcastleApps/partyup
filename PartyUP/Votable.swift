//
//  Votable.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-07-04.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import Foundation

enum Vote: Int, CustomDebugStringConvertible {
	case Down = -1, Meh = 0, Up = 1

	var debugDescription: String {
		get {
			switch self {
			case Down:
				return "Down"
			case Meh:
				return "Meh"
			case Up:
				return "Up"
			}
		}
	}
}

protocol Votable: Tastable {
	var rating: [Int] { get }
	var vote: Vote { get }
	var flag: Bool? { get }

	func setVote(vote: Vote, andFlag flag: Bool)
}