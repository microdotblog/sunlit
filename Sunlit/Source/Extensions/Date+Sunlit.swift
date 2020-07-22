//
//  Date+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/16/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

extension Date {
	
	func friendlyFormat() -> String {
		let secondsDifference = abs(self.timeIntervalSinceNow)
		let minutesDifference = secondsDifference / 60.0
		let hoursDifference = minutesDifference / 60.0
		let daysDifference = hoursDifference / 24.0
		
		if secondsDifference < 60.0 {
			return "Less than 1 minute ago"
		}
		if minutesDifference < 60.0 {
			if minutesDifference < 2.0 {
				return "1 minute ago"
			}
			return "\(Int(minutesDifference)) minutes ago"
		}
		if hoursDifference < 24.0 {
			if hoursDifference < 2.0 {
				return "1 hour ago"
			}
			return "\(Int(hoursDifference)) hours ago"
		}
		if daysDifference < 7.0 {
			if daysDifference < 2.0 {
				return "1 day ago"
			}
			return "\(Int(daysDifference)) days ago"
		}
		
		return self.uuShortMonthOfYear + " " + self.uuDayOfMonth + ", " + self.uuFourDigitYear
		//return self.uuFormat("M-d-yyyy")
	}
}
