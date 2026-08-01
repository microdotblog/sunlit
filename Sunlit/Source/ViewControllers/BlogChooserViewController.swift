//
//  BlogChooserViewController.swift
//  Sunlit
//

import UIKit

final class BlogChooserViewController: UITableViewController {

	private let blogs : [BlogSettings]
	private let onSelection : (BlogSettings) -> Void
	private let cellIdentifier = "BlogCell"

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

		self.title = "Choose Blog"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(
			image: UIImage(systemName: "chevron.backward"),
			style: .plain,
			target: self,
			action: #selector(onBack)
		)
		self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Back"

		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
		self.tableView.rowHeight = 52.0
		self.tableView.backgroundColor = .systemGroupedBackground
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		let selectedName = BlogSettings.blogForPublishing().blogName
		if let selectedRow = self.blogs.firstIndex(where: { $0.blogName == selectedName }) {
			self.tableView.scrollToRow(at: IndexPath(row: selectedRow, section: 0), at: .middle, animated: false)
		}
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

	@objc private func onBack() {
		self.dismiss(animated: true)
	}
}
