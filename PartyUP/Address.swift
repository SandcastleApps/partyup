//
//  Address.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-05-06.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import CoreLocation
import MapKit

struct Address: CustomDebugStringConvertible {
	var identifier: String?
	var name: String { return identifier ?? city }
	let coordinate: CLLocationCoordinate2D
	let city: String
	let province: String
	let country: String

	var location: CLLocation {
		return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
	}

	init(coordinate: CLLocationCoordinate2D, address: [String:String], name: String? = nil) {
		self.coordinate = coordinate
		self.city = address["city"] ?? "Anoncity"
		self.province = address["province"] ?? "Anonstate"
		self.country = address["country"] ?? "Anoncountry"
		self.identifier = name
	}

	init(coordinate: CLLocationCoordinate2D, address: CLPlacemark, name: String? = nil) {
		self.coordinate = coordinate
		self.city = address.locality ?? "Anoncity"
		self.province = address.administrativeArea ?? "Anonstate"
		self.country = address.country ?? "Anoncountry"
		self.identifier = name
	}

	init(coordinate: CLLocationCoordinate2D, mapkitAddress address: [NSObject:AnyObject], name: String? = nil) {
		self.coordinate = coordinate
		self.city = address["City"] as? String ?? address["SubLocality"] as? String ?? "Anoncity"
		self.province = address["State"] as? String ?? "Anonstate"
		self.country = address["Country"] as? String ?? "Anoncountry"
		self.identifier = name
	}

	init(plist: [NSObject:AnyObject]) {
		var remainder = plist
		var local = CLLocationCoordinate2D()
		if let coord = remainder.removeValueForKey("coordinate") as? [String:Double] {
			if let lat = coord["latitude"], let lon = coord["longitude"] {
				local = CLLocationCoordinate2D(latitude: lat, longitude: lon)
			}
		}
		let name = remainder.removeValueForKey("name") as? String
		self.init(coordinate: local, address: remainder as! [String:String], name: name)
	}

	var plist: [NSObject:AnyObject] {
		let local = ["latitude":NSNumber(double: coordinate.latitude),"longitude":NSNumber(double: coordinate.longitude)]
		let plist: [NSObject:AnyObject] = ["name":name,"coordinate":local,"city":city,"province":province,"country":country]
		return plist
	}

	var appleAddressDictionary: [String:AnyObject] {
		return ["Name":name,"City":city,"State":province,"Country":country]
	}

	var debugDescription: String { return "Name: \(name), Coordinate: \(coordinate.latitude),\(coordinate.longitude) Address: \(city), \(province), \(country)" }

	static func addressForCoordinates(coordinate: CLLocationCoordinate2D, completionHandler: (Address?, NSError?) -> Void) {
        geocoder.cancelGeocode()
		geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (places, error) in
			var address: Address?
			if let place = places?.first {
				address = Address(coordinate: coordinate, address: place)
			}
			completionHandler(address, error)
		}
	}
    
    static let geocoder = CLGeocoder()
}

extension MKPlacemark {
	convenience init(address: Address) {
		self.init(coordinate: address.coordinate, addressDictionary: address.appleAddressDictionary)
	}
}