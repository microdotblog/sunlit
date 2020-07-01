//
//  NSNotification+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/21/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

extension NSNotification.Name {
	
	static let showLoginNotification = NSNotification.Name(rawValue: "Show Login Notification")
	static let currentUserUpdatedNotification = NSNotification.Name(rawValue: "Current User Updated Notification")
	static let showTimelineNotification = NSNotification.Name(rawValue: "Show Timeline Notification")
	static let showCurrentUserProfileNotification = NSNotification.Name(rawValue: "Show Current User Profile Notification")
	static let showDiscoverNotification = NSNotification.Name(rawValue: "Show Discover Notification")
	static let showComposeNotification = NSNotification.Name(rawValue: "Show Compose Notification")
	static let showSettingsNotification = NSNotification.Name(rawValue: "Show Settings Notification")
	static let temporaryTokenReceivedNotification = NSNotification.Name(rawValue: "Temporary Token Received Notification")
	static let openURLNotification = NSNotification.Name("OpenURLNotification")
	static let viewConversationNotification = NSNotification.Name("View Conversation")
	static let viewPostNotification = NSNotification.Name("View Image")
	static let viewUserProfileNotification = NSNotification.Name("Display User Profile")
	static let notifyReplyPostedNotification = NSNotification.Name("Reply Response")
	static let refreshCellNotification = NSNotification.Name("Feed Image Loaded")
	static let scrollTableViewNotification = NSNotification.Name("Scroll Table View")
	static let emojiSelectedNotification = NSNotification.Name("Emoji Selected")
}
