//
//  SettingsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

private final class SettingsDividerView: UIView {
    private weak var tableView: UITableView?
    private let divider = UIView()

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init(frame: .zero)
        self.divider.backgroundColor = .systemGray4
        self.addSubview(self.divider)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.tableView?.bounds.width ?? self.bounds.width
        self.divider.frame = CGRect(x: (self.bounds.width - width) / 2, y: self.bounds.height - 1, width: width, height: 1)
    }
}

class SettingsViewController: UIViewController {

	@IBOutlet var signOutButton : UIButton!
    @IBOutlet var tableView : UITableView!
	@IBOutlet var settingsLabel : UILabel!
	
	var tableData : [BlogSettings] = []
	private let currentBlogCellIdentifier = "CurrentBlogCell"
	private let addExternalBlogCellIdentifier = "AddExternalBlogCell"
	private lazy var addExternalBlogButton = self.makeAddExternalBlogButton(action: #selector(onAddBlog))
	private lazy var addCheckInBlogButton = self.makeAddExternalBlogButton(action: #selector(onAddCheckInBlog))

	private func makeAddExternalBlogButton(action: Selector) -> UIButton {
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
		button.addTarget(self, action: action, for: .touchUpInside)
		return button
	}
    
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
		self.tableView.contentInset.top = 0.0
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
			(UIApplication.shared.delegate as? AppDelegate)?.performSignOut()
		}
	}
	
	@IBAction func onAddBlog() {
		self.addBlog(for: .posts)
	}

	@objc private func onAddCheckInBlog() {
		self.addBlog(for: .checkIns)
	}

	private func addBlog(for purpose: BlogSettings.PublishingPurpose) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let blogConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "ExternalBlogConfigurationViewController") as! ExternalBlogConfigurationViewController
        blogConfigurationViewController.publishingPurpose = purpose
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
		return 4
	}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 1 || indexPath.section == 3 {
			let cell = tableView.dequeueReusableCell(withIdentifier: self.addExternalBlogCellIdentifier, for: indexPath)
			cell.textLabel?.text = nil
			cell.backgroundColor = .clear
			cell.selectionStyle = .none
			cell.accessoryType = .none
			cell.accessoryView = nil

			let button = indexPath.section == 1 ? self.addExternalBlogButton : self.addCheckInBlogButton
			if button.superview !== cell.contentView {
				cell.contentView.subviews.filter { $0 is UIButton }.forEach { $0.removeFromSuperview() }
				button.removeFromSuperview()
				cell.contentView.addSubview(button)
				NSLayoutConstraint.activate([
					button.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
					button.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
				])
			}
			return cell
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: self.currentBlogCellIdentifier, for: indexPath)
		let purpose: BlogSettings.PublishingPurpose = indexPath.section == 2 ? .checkIns : .posts
		cell.textLabel?.text = purpose.blog.blogName
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
		if indexPath.section == 1 || indexPath.section == 3 {
			return
		}

		let purpose: BlogSettings.PublishingPurpose = indexPath.section == 2 ? .checkIns : .posts
		BlogChooserViewController.present(from: self, blogs: self.tableData, purpose: purpose) { [weak self] _ in
			self?.tableView.reloadData()
		}
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
    }

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard section == 2 else { return nil }
		let header = UIView()
		let label = UILabel()
		label.text = "For location check-ins, use blog:"
		label.font = .preferredFont(forTextStyle: .body)
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 0
		label.accessibilityTraits = .header
		label.translatesAutoresizingMaskIntoConstraints = false
		header.addSubview(label)
		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: header.leadingAnchor),
			label.trailingAnchor.constraint(equalTo: header.trailingAnchor),
			label.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
			label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -24)
		])
		return header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 2 ? UITableView.automaticDimension : .leastNormalMagnitude
	}

	func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
		return section == 2 ? 64 : 0
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard section == 1 else { return nil }
		return SettingsDividerView(tableView: tableView)
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0 || section == 2 { return .leastNormalMagnitude }
		return section == 1 ? 8 : tableView.sectionFooterHeight
	}
    
}
