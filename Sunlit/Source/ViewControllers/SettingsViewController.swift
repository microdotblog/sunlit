//
//  SettingsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

	@IBOutlet var signOutButton : UIButton!
    @IBOutlet var tableView : UITableView!
	@IBOutlet var settingsLabel : UILabel!
	
	var tableData : [BlogSettings] = []
	private let currentBlogCellIdentifier = "CurrentBlogCell"
	private let addExternalBlogCellIdentifier = "AddExternalBlogCell"
	private lazy var addExternalBlogButton : UIButton = {
		var configuration = UIButton.Configuration.gray()
		configuration.title = "Add External Blog"
		configuration.baseBackgroundColor = .systemGray5
		configuration.cornerStyle = .capsule
		configuration.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 18.0, bottom: 8.0, trailing: 18.0)
		configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
			var attributes = attributes
			attributes.font = .preferredFont(forTextStyle: .subheadline)
			return attributes
		}

		let button = UIButton(configuration: configuration)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addTarget(self, action: #selector(onAddBlog), for: .touchUpInside)
		return button
	}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
	
		self.setupNavigation()
		self.setupNotifications()
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.currentBlogCellIdentifier)
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.addExternalBlogCellIdentifier)
		self.tableView.rowHeight = 52.0
		self.tableView.sectionHeaderTopPadding = 8.0
		self.tableView.sectionHeaderHeight = .leastNormalMagnitude
		self.tableView.estimatedSectionHeaderHeight = 0.0
		self.tableView.contentInset.top = -24.0
		self.tableView.backgroundColor = .clear
		let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
		self.settingsLabel.text = buildString.isEmpty ? versionString : "\(versionString) (\(buildString))"
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        self.tableData = BlogSettings.publishedBlogs()
        self.tableView.reloadData()
	}
	
	func setupNavigation() {
		self.navigationItem.title = "Settings"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Credits", style: .plain, target: self, action: #selector(onViewCredits))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onDismiss))
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(finishedExternalConfigNotification), name: .finishedExternalConfigNotification, object: nil)
	}
		
	@objc func finishedExternalConfigNotification(_ notification: Notification) {
        self.tableData = BlogSettings.publishedBlogs()
        self.tableView.reloadData()
	}
	
	@IBAction func onDismiss() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onSignout() {

		Dialog(self).question(title: nil, question: "Are you sure you want to sign out of your Micro.blog account?", accept: "Sign Out", cancel: "Cancel") {
			Settings.logout()

            UIApplication.shared.applicationIconBadgeNumber = 0

			NotificationCenter.default.post(name: .currentUserUpdatedNotification, object: nil)
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func onAddBlog() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let blogConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "ExternalBlogConfigurationViewController")
        self.navigationController?.pushViewController(blogConfigurationViewController, animated: true)
	}
	
	@IBAction @objc func onViewCredits() {
		let storyboard: UIStoryboard = UIStoryboard(name: "About", bundle: nil)
		let about_controller = storyboard.instantiateViewController(withIdentifier: "AboutViewController")
		self.navigationController?.pushViewController(about_controller, animated: true)
	}
	

}

extension SettingsViewController : UITableViewDataSource, UITableViewDelegate {

	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: self.addExternalBlogCellIdentifier, for: indexPath)
			cell.textLabel?.text = nil
			cell.backgroundColor = .clear
			cell.selectionStyle = .none
			cell.accessoryType = .none
			cell.accessoryView = nil

			if self.addExternalBlogButton.superview == nil {
				cell.contentView.addSubview(self.addExternalBlogButton)
				NSLayoutConstraint.activate([
					self.addExternalBlogButton.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
					self.addExternalBlogButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
				])
			}
			return cell
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: self.currentBlogCellIdentifier, for: indexPath)
		cell.textLabel?.text = BlogSettings.blogForPublishing().blogName
		cell.textLabel?.font = .preferredFont(forTextStyle: .body)
		cell.textLabel?.textColor = .label
		cell.textLabel?.textAlignment = .natural
		let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12.0, weight: .regular)
		let chevron = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: symbolConfiguration))
		chevron.tintColor = .secondaryLabel
		cell.accessoryType = .none
		cell.accessoryView = chevron
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.section == 1 {
			return
		}

		BlogChooserViewController.present(from: self, blogs: self.tableData) { [weak self] _ in
			self?.tableView.reloadData()
		}
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
    }
    
}
