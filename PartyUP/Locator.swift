//
//  Locator.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-10-27.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import CoreLocation
import Foundation

class Locator: NSObject, CLLocationManagerDelegate {

	struct LocatorNotifications {
		static let LocatorUpdateNotification = "ScaLocatorUpdate"
	}

	var location: CLLocation? { return manager.location }

	override init() {
		super.init()
		
		if CLLocationManager.locationServicesEnabled() {
			manager.delegate = self
			manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

			if CLLocationManager.authorizationStatus() == .NotDetermined {
				manager.requestWhenInUseAuthorization()
			}
		}
	}

	func update() {
		let status = CLLocationManager.authorizationStatus()
		if  status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
			manager.startUpdatingLocation()
		}
	}

	// MARK: - Location Servicing

	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		update()
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = manager.location where location.horizontalAccuracy <= manager.desiredAccuracy {
				manager.stopUpdatingLocation()
				notifier.postNotificationName(LocatorNotifications.LocatorUpdateNotification, object: self)
		}
	}

	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		notifier.postNotificationName(LocatorNotifications.LocatorUpdateNotification, object: self)
	}

	// MARK: - Shared Locator

	static var sharedLocator = Locator()

	// MARK: - Private

	private let notifier = NSNotificationCenter.defaultCenter()
	private let manager = CLLocationManager()
}
