//
//  SunlitMentions.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation
import Snippets

class SunlitMentions {
	static let shared = SunlitMentions()
	private var mentions : [SunlitPost] = []
	private let cachedMentionDateKey = "LatestSunlitMentionDate"

	func newMentionCount() -> Int {

		let lastMentionViewedDate = self.lastViewedMentionDate()
		var mentionCount = 0
		for mention in self.mentions {
			if let publishedDate = mention.publishedDate {
				if publishedDate > lastMentionViewedDate {
					mentionCount = mentionCount + 1
				}
			}
		}
		
		return mentionCount
	}
	
	func allMentions() -> [SunlitPost] {
		return self.mentions
	}

	func allMentionsViewed() {
		UserDefaults.standard.setValue(Date(), forKey: self.cachedMentionDateKey)
		NotificationCenter.default.post(name: .mentionsUpdatedNotification, object: nil)
	}

	func update(_ callback : @escaping () -> () ) {
		Snippets.shared.fetchCurrentUserMentions { (error, posts) in
		
			DispatchQueue.main.async {
				self.mentions = []
				
				for post in posts {
					let sunlitPost = SunlitPost.create(post)
					//if sunlitPost.images.count > 0 {
						self.mentions.append(sunlitPost)
					//}
				}
				
				callback()
				NotificationCenter.default.post(name: .mentionsUpdatedNotification, object: nil)
			}
		}
	}
	
	private init() {
		self.update {
		}
	}
	
	private func lastViewedMentionDate() -> Date {
		if let date = UserDefaults.standard.value(forKey: self.cachedMentionDateKey) as? Date {
			return date
		}
		
		return .distantPast
	}

}
