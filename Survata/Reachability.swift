//
//  Reachability.swift
//  Survata
//
//  Created by Rex Sheng on 2/15/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import SystemConfiguration

extension Survey {
	static func isConnectedToNetwork() -> Bool {
		var zeroAddress = sockaddr_in()
		zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
		zeroAddress.sin_family = sa_family_t(AF_INET)
		let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
			SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
		}
		var flags = SCNetworkReachabilityFlags()
		if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
			return false
		}
		let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
		let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
		return (isReachable && !needsConnection)
	}
}
