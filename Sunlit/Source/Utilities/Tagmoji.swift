//
//  Tagmoji.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/17/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation
import Snippets

class Tagmoji {
	
	static let shared = Tagmoji()
	
	func refresh(_ completion: @escaping ((Bool)-> Void)) {
		Snippets.Microblog.fetchTagmojiCategories { (error, tagmoji) in
			
			let changed = self.updateFromServerResponse(tagmoji)
			completion(changed)
		}
	}
	
	func updateFromServerResponse(_ tagmoji : [[String : Any]]) -> Bool {
		var newDictionary : [String : Any] = [:]
		var newEmoji : [String] = []
		
		for d in tagmoji {
			if let symbol = d["emoji"] as? String {
				// Keep the photos collection when another category uses the same emoji.
				if let existing = newDictionary[symbol] as? [String: Any],
					existing["name"] as? String == "photos" {
					continue
				}
				if newDictionary[symbol] == nil {
					newEmoji.append(symbol)
				}
				newDictionary[symbol] = d
			}
		}
		
		let changed = newEmoji != self.emoji || !NSDictionary(dictionary: newDictionary).isEqual(to: self.dictionary)
		
		self.dictionary = newDictionary
		self.emoji = newEmoji
		
		return changed
	}
	
	func frequentlyUsedEmoji() -> [String] {
		return ["🙂","👍","❤️","😂","😍","😌","🤔","🙏","🔥"]
	}
	
	func all() -> [String] {
		return self.emoji
	}
	
	func routeFor(tagmoji : String) -> String? {
		return self.dictionaryFor(tagmoji)["name"] as? String
	}
	
	func tileFor(tagmoji : String) -> String? {
		return self.dictionaryFor(tagmoji)["title"] as? String
	}
	
	
	private init() {
		self.refresh { (refreshed) in
		}
	}
	
	private func dictionaryFor(_ emoji : String) -> [String : Any] {
		return self.dictionary[emoji] as? [String : Any] ?? [:]
	}

	private var dictionary : [String : Any] = [:]
	private var emoji : [String] = []

}
