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
	static let micropubTokenReceivedNotification = NSNotification.Name(rawValue: "Micropub Token Received Notification")
	static let finishedExternalConfigNotification = NSNotification.Name(rawValue: "Finished External Config Notification")
	static let openURLNotification = NSNotification.Name("Open URL Notification")
	static let viewConversationNotification = NSNotification.Name("View Conversation Notification")
	static let viewPostNotification = NSNotification.Name("View Image Notification")
	static let viewUserProfileNotification = NSNotification.Name("Display User Profile Notification")
	static let notifyReplyPostedNotification = NSNotification.Name("Reply Response Notification")
	static let refreshCellNotification = NSNotification.Name("Feed Image Loaded Notification")
	static let scrollTableViewNotification = NSNotification.Name("Scroll Table View Notification")
	static let emojiSelectedNotification = NSNotification.Name("Emoji Selected Notification")
	static let splitViewWillCollapseNotification = NSNotification.Name("Splitview Will Collapse Notification")
	static let splitViewWillExpandNotification = NSNotification.Name("Splitview Will Expand Notification")
}
