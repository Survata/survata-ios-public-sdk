//
//  Networking.swift
//  Survata
//
//  Created by Rex Sheng on 2/11/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import Foundation

extension Survey {
	static func post(urlString: String, json: [String: AnyObject], completion: ([String: AnyObject]?, NSError?) -> Void) {
		guard let url = NSURL(string: urlString) else {
			return
		}
		let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 20)
		request.HTTPMethod = "POST"
		let userAgent: String = {
			if let info = NSBundle.mainBundle().infoDictionary {
				let executable: AnyObject = info[kCFBundleExecutableKey as String] ?? "Unknown"
				let bundle: AnyObject = info[kCFBundleIdentifierKey as String] ?? "Unknown"
				let version: AnyObject = info["CFBundleShortVersionString"] ?? "Unknown"

				let mutableUserAgent = NSMutableString(string: "\(executable)/\(bundle) Survata/iOS/\(version)") as CFMutableString
				let transform = NSString(string: "Any-Latin; Latin-ASCII; [:^ASCII:] Remove") as CFString

				if CFStringTransform(mutableUserAgent, UnsafeMutablePointer<CFRange>(nil), transform, false) {
					return mutableUserAgent as String
				}
			}
			return "Survata/iOS"
		}()
		request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
		request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
		request.setValue("application/javascript", forHTTPHeaderField: "Content-Type")
		request.setValue(json["mobileAdId"] as! String?, forHTTPHeaderField: "GAID")
		let session = NSURLSession.sharedSession()
		let task = session.dataTaskWithRequest(request) { (data, _, error) in
			if let data = data,
				object = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] {
				dispatch_async(dispatch_get_main_queue()) {
					completion(object, nil)
				}
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					completion(nil, error)
				}
			}
		}
		task.resume()
	}
}
