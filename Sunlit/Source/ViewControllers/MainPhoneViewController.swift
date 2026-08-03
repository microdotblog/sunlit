//
//  MainPhoneViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class MainPhoneViewController: UITabBarController {

	static var needsMentionsSwitch = false

	let discoverViewController: DiscoverViewController
	let timelineViewController: TimelineViewController
	let mentionsViewController: MentionsViewController
	var currentViewController: ContentViewController?
	private var didPrepareInitialTab = false

	init(timelineViewController: TimelineViewController, mentionsViewController: MentionsViewController, discoverViewController: DiscoverViewController) {
		self.timelineViewController = timelineViewController
		self.mentionsViewController = mentionsViewController
		self.discoverViewController = discoverViewController
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.delegate = self
		self.setupTabs()
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdated), name: .currentUserUpdatedNotification, object: nil)
	}

	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)

		if parent != nil {
			self.prepareInitialTabIfNeeded()
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.reloadTabs()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if MainPhoneViewController.needsMentionsSwitch {
			MainPhoneViewController.needsMentionsSwitch = false
			self.onShowMentions()
		}
	}

	private func setupTabs() {
		self.timelineViewController.tabBarItem = UITabBarItem(
			title: "Timeline",
			image: UIImage(systemName: "bubble.left.and.bubble.right"),
			selectedImage: nil
		)
		self.mentionsViewController.tabBarItem = UITabBarItem(
			title: "Mentions",
			image: UIImage(systemName: "at"),
			selectedImage: nil
		)
		self.discoverViewController.tabBarItem = UITabBarItem(
			title: "Discover",
			image: UIImage(systemName: "magnifyingglass"),
			selectedImage: nil
		)

		self.tabBar.tintColor = UIColor(named: "color_tab_selected")
		self.tabBar.unselectedItemTintColor = UIColor(named: "color_tab_normal")

//		let appearance = UITabBarAppearance()
//		appearance.configureWithDefaultBackground()
//		appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
//		appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.35)
//		self.tabBar.standardAppearance = appearance
//		self.tabBar.scrollEdgeAppearance = appearance

		self.updateAvailableTabs()
	}

	private func updateAvailableTabs() {
		let isSignedIn = Settings.isSignedIn
		if !isSignedIn && self.currentViewController === self.mentionsViewController {
			self.select(self.timelineViewController)
		}

		let availableViewControllers: [UIViewController]
		if isSignedIn {
			availableViewControllers = [
				self.timelineViewController,
				self.mentionsViewController,
				self.discoverViewController
			]
		}
		else {
			availableViewControllers = [
				self.timelineViewController,
				self.discoverViewController
			]
			self.mentionsViewController.tabBarItem.badgeValue = nil
		}

		self.setViewControllers(availableViewControllers, animated: false)
	}

	private func prepareInitialTabIfNeeded() {
		guard !self.didPrepareInitialTab else {
			return
		}

		self.didPrepareInitialTab = true
		self.viewControllers?.forEach { $0.loadViewIfNeeded() }
		self.selectedViewController = self.timelineViewController
		self.currentViewController = self.timelineViewController
		self.timelineViewController.prepareToDisplay()
		self.updateMentionsBadge()
	}

	func reloadTabs() {
		self.timelineViewController.tableView.reloadData()
		self.discoverViewController.tableView.reloadData()
		self.discoverViewController.collectionView.reloadData()
		if self.mentionsViewController.isViewLoaded {
			self.mentionsViewController.tableView.reloadData()
		}
	}

	@objc func handleCurrentUserUpdated() {
		DispatchQueue.main.async {
			self.updateAvailableTabs()
		}
	}

	@objc func handleUserMentionsUpdated() {
		DispatchQueue.main.async {
			self.updateMentionsBadge()
		}
	}

	private func updateMentionsBadge() {
		guard Settings.isSignedIn else {
			self.mentionsViewController.tabBarItem.badgeValue = nil
			return
		}

		let mentionCount = SunlitMentions.shared.newMentionCount()
		self.mentionsViewController.tabBarItem.badgeValue = mentionCount > 0 ? String(mentionCount) : nil
	}

	private func transition(to viewController: ContentViewController) {
		let previousViewController = self.currentViewController
		guard previousViewController !== viewController else {
			return
		}

		previousViewController?.prepareToHide()
		self.currentViewController = viewController
		viewController.loadViewIfNeeded()

		if viewController === self.timelineViewController {
			self.timelineViewController.loadTimeline()
		}

		viewController.prepareToDisplay()
	}

	private func select(_ viewController: ContentViewController) {
		if self.currentViewController === viewController {
			viewController.handleScrollToTopGesture()
			return
		}

		self.selectedViewController = viewController
		self.transition(to: viewController)
	}

	func onShowTimeline() {
		self.select(self.timelineViewController)
	}

	func onShowMentions() {
		guard Settings.isSignedIn else {
			self.onShowTimeline()
			return
		}

		if self.viewControllers?.contains(where: { $0 === self.mentionsViewController }) != true {
			self.updateAvailableTabs()
		}
		self.select(self.mentionsViewController)
	}

	func onShowDiscover() {
		self.select(self.discoverViewController)
	}
}

extension MainPhoneViewController: UITabBarControllerDelegate {

	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		if viewController === self.currentViewController {
			self.currentViewController?.handleScrollToTopGesture()
			return false
		}

		return true
	}

	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if let contentViewController = viewController as? ContentViewController {
			self.transition(to: contentViewController)
		}
	}
}
