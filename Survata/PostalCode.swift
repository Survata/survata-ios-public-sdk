//
//  PostalCode.swift
//  Survata
//
//  Created by Rex Sheng on 2/15/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import CoreLocation

enum Geocode {
	class GeocodeContainer: NSObject, CLLocationManagerDelegate {
		var locationManager: CLLocationManager!

		var callback: ((CLLocation?) -> Void)?

		func current(_ callback: @escaping (CLLocation?) -> Void) {
			locationManager?.stopUpdatingLocation()
			self.callback = callback
			if locationManager == nil {
				locationManager = CLLocationManager()
				locationManager.delegate = self
				locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
				locationManager.requestWhenInUseAuthorization()
			}
			locationManager.startUpdatingLocation()
		}

		func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
			callback?(locations.last)
			callback = nil
			manager.stopUpdatingLocation()
		}

		func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
			callback?(manager.location)
			callback = nil
			print(error.localizedDescription)
			manager.stopUpdatingLocation()
		}

		deinit {
			print("deinit GeocodeContainer")
		}
	}
	fileprivate static var geoContainer = GeocodeContainer()
	case location(CLLocation)
	case current

	func get(_ closure: @escaping (String?) -> ()) {
		switch self {
		case .location(let location):
			CLGeocoder().reverseGeocodeLocation(location) { (addresses, error) in
				if let addresses = addresses {
					for address in addresses where address.isoCountryCode == "US" {
						if let postalCode = address.postalCode {
							Cache(file: "geocode")?.saveJSON(["postalCode": postalCode] as AnyObject)
							closure(postalCode)
							return
						}
					}
				}
				closure(nil)
			}
		case .current:
			if let cached = Cache(file: "geocode")?.loadJSON(expireAfter: 86400) as? [String: AnyObject] {
				if let postalCode = cached["postalCode"] as? String {
					closure(postalCode)
					return
				}
			}
			switch CLLocationManager.authorizationStatus() {
			case .authorizedAlways, .authorizedWhenInUse:
				Geocode.geoContainer.current { (location) in
					if let location = location {
						Geocode.location(location).get(closure)
					} else {
						closure(nil)
					}
				}
			default:
				closure(nil)
			}
		}
	}
}

struct Cache {
	let filePath: String
	init?(file: String) {
		let home = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        if let home = home {
            let folder = home + "/survata"
			if !FileManager.default.fileExists(atPath: folder) {
				do {
					try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
				} catch {
					return nil
				}
			}
			filePath = "\(folder)/\(file)"
		} else {
			return nil
		}
	}

	func loadJSON(expireAfter time: TimeInterval) -> AnyObject? {
		if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
			let lastModified = attr[FileAttributeKey.modificationDate] as? Date {
				let time = lastModified.timeIntervalSinceNow + time
				if time < 0 {
					return nil
				}
		}
		if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
			let object = try? JSONSerialization.jsonObject(with: data, options: []) {
				return object as AnyObject?
		}
		return nil
	}

	func saveJSON(_ json: AnyObject) {
		if let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
            try? data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
		}
	}
}
