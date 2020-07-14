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
		Snippets.shared.fetchTagmojiCategories { (error, tagmoji) in
			
			let changed = self.updateFromServerResponse(tagmoji)
			completion(changed)
		}
	}
	
	func updateFromServerResponse(_ tagmoji : [[String : Any]]) -> Bool {
		var newDictionary : [String : Any] = [:]
		var changed = false
		for d in tagmoji {
			if let symbol = d["emoji"] as? String {
				newDictionary[symbol] = d
			}
		}
		
		if newDictionary.count != self.dictionary.count {
			changed = true
		}
		else {
			let keys = newDictionary.keys
			for key in keys {
				if self.dictionary[key] == nil {
					changed = true
				}
			}
		}
		
		self.dictionary = newDictionary
		return changed
	}
	
	func frequentlyUsedEmoji() -> [String] {
		return ["🙂","👍","❤️","😂","😭","🤣","😍","😌","🔥","🤔","😫","🙄","🙏"]
	}
	
	func all() -> [String] {
		var tagmoji : [String] = []
		for key in self.dictionary.keys {
			tagmoji.append(key)
		}
		
		return tagmoji
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

}
