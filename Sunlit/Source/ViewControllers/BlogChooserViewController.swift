//
//  BlogChooserViewController.swift
//  Sunlit
//

import UIKit

final class BlogChooserViewController: UITableViewController {

	private let blogs : [BlogSettings]
	private let onSelection : (BlogSettings) -> Void
	private let cellIdentifier = "BlogCell"

	static func present(from viewController : UIViewController, blogs : [BlogSettings], onSelection : @escaping (BlogSettings) -> Void) {
		let chooser = BlogChooserViewController(blogs: blogs, onSelection: onSelection)
		let navigationController = UINavigationController(rootViewController: chooser)
		navigationController.modalPresentationStyle = .pageSheet
		navigationController.preferredContentSize = CGSize(width: 420.0, height: 520.0)

		if let sheet = navigationController.sheetPresentationController {
			sheet.detents = [.medium()]
			sheet.prefersGrabberVisible = false
			sheet.prefersScrollingExpandsWhenScrolledToEdge = false
			sheet.preferredCornerRadius = 24.0
		}

		viewController.present(navigationController, animated: true)
	}

	init(blogs : [BlogSettings], onSelection : @escaping (BlogSettings) -> Void) {
		self.blogs = blogs
		self.onSelection = onSelection
		super.init(style: .insetGrouped)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Blogs"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(
			image: UIImage(systemName: "xmark"),
			style: .plain,
			target: self,
			action: #selector(onClose)
		)
		self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Close"

		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
		self.tableView.rowHeight = 52.0
		self.tableView.sectionHeaderTopPadding = 8.0
		self.tableView.sectionHeaderHeight = .leastNormalMagnitude
		self.tableView.estimatedSectionHeaderHeight = 0.0
		self.tableView.contentInset.top = -24.0
		self.tableView.backgroundColor = .systemGroupedBackground
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.blogs.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
		let blog = self.blogs[indexPath.row]
		cell.textLabel?.text = blog.blogName
		cell.textLabel?.font = .preferredFont(forTextStyle: .body)
		cell.textLabel?.textColor = .label
		cell.accessoryType = blog.blogName == BlogSettings.blogForPublishing().blogName ? .checkmark : .none
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let blog = self.blogs[indexPath.row]
		BlogSettings.setBlogForPublishing(blog)
		self.onSelection(blog)
		self.dismiss(animated: true)
	}

	@objc private func onClose() {
		self.dismiss(animated: true)
	}
}
