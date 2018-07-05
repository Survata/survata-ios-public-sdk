//
//  Networking.swift
//  Survata
//
//  Created by Rex Sheng on 2/11/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import Foundation

extension Survey {
	static func post(urlString: String, json: [String: AnyObject], completion: @escaping ([String: AnyObject]?, Error?) -> Void) {
		guard let url = URL(string: urlString) else {
			return
		}
		var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
		request.httpMethod = "POST"
        // logic inspired by Alamofire's user agent handling
        // see https://github.com/Alamofire/Alamofire/blob/305258733be64dd99a7f70cf777b33112d738571/Source/Manager.swift for context
		let userAgent: String = {
			if let info = Bundle.main.infoDictionary {
				let executable: AnyObject = info[kCFBundleExecutableKey as String] as AnyObject? ?? "Unknown" as AnyObject
				let bundle: AnyObject = info[kCFBundleIdentifierKey as String] as AnyObject? ?? "Unknown" as AnyObject
				let version: AnyObject = info["CFBundleShortVersionString"] as AnyObject? ?? "Unknown" as AnyObject

				let mutableUserAgent = NSMutableString(string: "\(executable)/\(bundle) Survata/iOS/\(version)") as CFMutableString
				let transform = NSString(string: "Any-Latin; Latin-ASCII; [:^ASCII:] Remove") as CFString

                if CFStringTransform(mutableUserAgent, nil, transform, false) {
                    return mutableUserAgent as String
                }
			}
			return "Survata/iOS"
		}()
		request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
		request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
		request.setValue("application/javascript", forHTTPHeaderField: "Content-Type")
		request.setValue(json["mobileAdId"] as! String?, forHTTPHeaderField: "GAID")
		let session = URLSession.shared
		let task = session.dataTask(with: request, completionHandler: { (data, _, error) in
			if let data = data,
				let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
				DispatchQueue.main.async {
					completion(object, nil)
				}
			} else {
				DispatchQueue.main.async {
					completion(nil, error)
				}
			}
		})
		task.resume()
	}
}
