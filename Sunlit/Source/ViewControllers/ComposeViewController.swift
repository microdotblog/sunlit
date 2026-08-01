//
//  ComposeViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Mantis
import Snippets
import UUSwiftNetworking
import PhotosUI

enum ComposeCollectionViewMetrics {
	static let sectionHorizontalInset: CGFloat = 12.0
	static let textVerticalInset: CGFloat = 16.0
	static let sectionBackgroundOverlap: CGFloat = 10.0
	static let textContainerInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
	static let textLineFragmentPadding: CGFloat = 5.0

	static func mediaItemSize(_ collectionViewWidth: CGFloat) -> CGSize {
		let availableWidth = collectionViewWidth - (sectionHorizontalInset * 2.0)
		let length = min(200.0, floor(availableWidth / 3.0))
		return CGSize(width: length, height: length)
	}
}

private final class ComposeMediaBackgroundView: UICollectionReusableView {
	private let topGradientLayer = CAGradientLayer()

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configureAppearance()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.configureAppearance()
	}

	private func configureAppearance() {
		self.backgroundColor = .secondarySystemBackground
		self.layer.cornerRadius = 12.0
		self.layer.cornerCurve = .continuous
		self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
		self.clipsToBounds = true

		self.topGradientLayer.colors = [
			UIColor.black.withAlphaComponent(0.14).cgColor,
			UIColor.black.withAlphaComponent(0.05).cgColor,
			UIColor.clear.cgColor
		]
		self.topGradientLayer.locations = [0.0, 0.45, 1.0]
		self.topGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
		self.topGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
		self.layer.addSublayer(self.topGradientLayer)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		self.topGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: 18.0)
	}
}

private final class ComposeCollectionViewLayout: UICollectionViewFlowLayout {
	private static let mediaBackgroundKind = "ComposeMediaBackground"
	private var mediaBackgroundAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

	override init() {
		super.init()
		self.register(ComposeMediaBackgroundView.self, forDecorationViewOfKind: Self.mediaBackgroundKind)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.register(ComposeMediaBackgroundView.self, forDecorationViewOfKind: Self.mediaBackgroundKind)
	}

	override func prepare() {
		super.prepare()
		self.mediaBackgroundAttributes.removeAll()

		guard let collectionView else {
			return
		}

		for section in 0..<collectionView.numberOfSections {
			let itemCount = collectionView.numberOfItems(inSection: section)
			let mediaCount = itemCount - 2
			guard mediaCount > 0,
				let textAttributes = super.layoutAttributesForItem(at: IndexPath(item: 0, section: section)) else {
				continue
			}

			let mediaAttributes = (1...mediaCount).compactMap {
				super.layoutAttributesForItem(at: IndexPath(item: $0, section: section))
			}
			guard let mediaBottom = mediaAttributes.map(\.frame.maxY).max() else {
				continue
			}

			let backgroundTop = textAttributes.frame.maxY
				- ComposeCollectionViewMetrics.textVerticalInset
				- ComposeCollectionViewMetrics.sectionBackgroundOverlap
			let indexPath = IndexPath(item: 0, section: section)
			let attributes = UICollectionViewLayoutAttributes(
				forDecorationViewOfKind: Self.mediaBackgroundKind,
				with: indexPath
			)
			attributes.frame = CGRect(
				x: ComposeCollectionViewMetrics.sectionHorizontalInset,
				y: backgroundTop,
				width: collectionView.bounds.width - (ComposeCollectionViewMetrics.sectionHorizontalInset * 2.0),
				height: mediaBottom - backgroundTop
			)
			attributes.zIndex = -1
			self.mediaBackgroundAttributes[indexPath] = attributes
		}
	}

	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		var attributes = super.layoutAttributesForElements(in: rect) ?? []
		attributes.append(contentsOf: self.mediaBackgroundAttributes.values.filter { $0.frame.intersects(rect) })
		return attributes
	}

	override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		guard elementKind == Self.mediaBackgroundKind else {
			return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
		}
		return self.mediaBackgroundAttributes[indexPath]
	}

	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let collectionView else {
			return false
		}
		return collectionView.bounds.width != newBounds.width
	}
}


class ComposeViewController: UIViewController {

	@IBOutlet var titleField : UITextField!
	@IBOutlet var titleHeightConstraint : NSLayoutConstraint!
	@IBOutlet var disabledInterface : UIView!
	@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var keyboardAccessoryView : UIView!
	@IBOutlet var keyboardAccessoryViewBottomConstraint : NSLayoutConstraint!
	@IBOutlet var blogSelectorButton : UIButton!

	var sections : [SunlitComposition] = []
	var textViewDictionary : [UITextView : SunlitComposition] = [ : ]
	var needsInitialFirstResponder = true
	var sectionToAddMedia = 0
	var croppingMedia : SunlitMedia? = nil
	var uploading = false
	let mediaUpLoader = MediaUploader()
	var activeUpload : UUHttpRequest? = nil

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.bringSubviewToFront(self.disabledInterface)
		self.titleHeightConstraint.constant = 0.0
		
		self.configureCollectionView()
		self.configureNavigationController()
		self.configureKeyboardAccessoryView()
        self.setupAppExtensionElements()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	func configureCollectionView() {
		let flowLayout = ComposeCollectionViewLayout()
		flowLayout.estimatedItemSize = .zero
		flowLayout.minimumLineSpacing = 0.0
		flowLayout.minimumInteritemSpacing = 0.0
		self.collectionView.collectionViewLayout = flowLayout
		self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		self.collectionView.dragInteractionEnabled = true
	}
	
	func configureNavigationController() {
		self.navigationItem.title = "New Post"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
	}
	
	func configureKeyboardAccessoryView() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // There is a situation where, because of update migrations, the blog configuration can
        // end up not having a valid token. Try to detect that here and fix.
        let blogSettings = BlogSettings.blogForPublishing()
        if let config = blogSettings.snippetsConfiguration {
            if config.type == .micropub && config.micropubToken.count == 0 {
                config.micropubToken = Settings.snippetsToken() ?? ""

                blogSettings.snippetsConfiguration = config
            }
        }

        self.blogSelectorButton.setTitle(BlogSettings.blogForPublishing().blogName, for: .normal)
        self.blogSelectorButton.isEnabled = BlogSettings.publishedBlogs().count > 1
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		.darkContent
	}
    	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func addMedia(_ media : SunlitMedia, _ description : String) {
		if self.sectionToAddMedia >= self.sections.count {
			let section = SunlitComposition()
			section.text = description
			section.media.append(media)
			self.sections.append(section)
		}
		else {
			let section = self.sections[self.sectionToAddMedia]
			section.media.append(media)
		}

		if self.collectionView != nil {
			self.collectionView.reloadData()
		}
		
		if self.sections.count > 1 {
			UIView.animate(withDuration: 0.15) {
				self.titleHeightConstraint.constant = 60.0
				self.view.layoutIfNeeded()
			}
		}
	}
	
	func onImageTapped(_ section : Int, _ item : Int) {

		self.view.endEditing(true)

		let sectionData = self.sections[section]

		var editTextTitle = "Add Description"
		if sectionData.media[item].altText.count > 0 {
			editTextTitle = "Edit Description"
		}
		
		let altTextAction = UIAlertAction(title: editTextTitle, style: .default) { (action) in
			self.onEditAltText(sectionData, item)
		}
		
		let cropAction = UIAlertAction(title: "Crop", style: .default) { (action) in
			self.onCropImage(sectionData, item: item, section: section)
		}

		let deleteAction = UIAlertAction(title: "Remove", style: .default) { (action) in
			self.onRemoveImage(sectionData, item: item, section: section)
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
		}

        let media = sectionData.media[item]

		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // We can't crop media that has already been published...
        if media.publishedPath == nil {
            alertController.addAction(cropAction)
        }

		alertController.addAction(deleteAction)
		alertController.addAction(altTextAction)
		alertController.addAction(cancelAction)
		
		if let popoverController = alertController.popoverPresentationController {
			popoverController.sourceView = self.view
			popoverController.sourceRect = CGRect(x: self.view.center.x, y: self.view.center.y, width: 0, height: 0)
			popoverController.permittedArrowDirections = []
		}
		
		self.present(alertController, animated: true, completion: nil)
	}

    @available(iOS 14, *)
    func iOS14PhotoPicker() -> UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 0
        configuration.preferredAssetRepresentationMode = .automatic

        let pickerController = PHPickerViewController(configuration: configuration)
        pickerController.delegate = self
        return pickerController
    }

    func defaultPhotoPicker() -> UIViewController {
        let pickerController = UIImagePickerController()
        pickerController.modalPresentationCapturesStatusBarAppearance = true
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image", "public.movie"]
        pickerController.sourceType = .savedPhotosAlbum
        return pickerController
    }

	@objc func onAddPhoto(_ section : Int) {
		self.sectionToAddMedia = section

        var pickerController : UIViewController!

        if #available(iOS 14, *) {
            pickerController = iOS14PhotoPicker()
        }
        else {
            pickerController = defaultPhotoPicker()
        }

		self.present(pickerController, animated: true, completion: nil)
	}

	@objc func onPost() {
		
		// Force the keyboard to go away...
		self.view.endEditing(true)
		
		// In case a double tap got through somehow...
		if self.uploading == true {
			return
		}
		
		self.uploading = true
		self.navigationItem.rightBarButtonItem?.isEnabled = false

		UIView.animate(withDuration: 0.15) {
			self.disabledInterface.alpha = 1.0
		}

		self.uploadComposition()
	}
	
	@IBAction func onSelectBlogConfiguration() {
		Dialog(self).selectBlog {
            self.blogSelectorButton.setTitle(BlogSettings.blogForPublishing().blogName, for: .normal)
		}
	}
	
	@objc func onCancel() {
		self.view.endEditing(true)
		
		UIView.animate(withDuration: 0.15) {
			self.disabledInterface.alpha = 0.0
		}

		if !self.uploading {
            if let extensionContext = self.extensionContext {
                extensionContext.cancelRequest(withError: URLError(URLError.cancelled))
            }
            else {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
		}
		else {
			self.cancelPosting()
		}
	}

	func onRemoveImage(_ sectionData : SunlitComposition, item : Int, section : Int) {
		sectionData.media.remove(at: item)
		
		if sectionData.media.count == 0 {
			self.sections.remove(at: section)
		}
		
		self.collectionView.reloadData()
	}

	func onCropImage(_ sectionData : SunlitComposition, item : Int, section : Int) {
		
		let media = sectionData.media[item]
		let image = media.getImage()
		let cropViewController = Mantis.cropViewController(image: image)
		cropViewController.delegate = self
		self.croppingMedia = media
		cropViewController.modalPresentationStyle = .fullScreen
		self.present(cropViewController, animated: true)
	}

	@IBAction func onDismissKeyboard() {
		self.view.endEditing(true)
	}
	
	@objc func keyboardOnScreenNotification(_ notification : Notification) {
		
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				let frame = value.cgRectValue
				
				UIView.animate(withDuration: 0.25) {
					self.keyboardAccessoryView.alpha = 1.0
					self.keyboardAccessoryViewBottomConstraint.constant = frame.size.height - self.view.safeAreaInsets.bottom
					self.view.layoutIfNeeded()
				}
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
		
		UIView.animate(withDuration: 0.25) {
			self.keyboardAccessoryViewBottomConstraint.constant = 0
			self.view.layoutIfNeeded()
		}
	}
	
    /* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    MARK: -
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    func onEditAltText(_ section : SunlitComposition, _ item : Int) {


		let storyboard: UIStoryboard = UIStoryboard(name: "Compose", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "AltTextController") as! AltTextController
        controller.media = section.media[item]
		self.present(controller, animated: true, completion: nil)
    }
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func uploadComposition() {

        Snippets.Configuration.publishing = BlogSettings.blogForPublishing().snippetsConfiguration!
        
		let title : String = self.titleField.text ?? ""
		self.uploadMedia { (mediaDictionary : [SunlitMedia : MediaLocation]) in
			
			// If we aren't still uploading, it means the user has requested a cancel...
			if !self.uploading {
				return
			}

            if self.sections.count <= 1 && Snippets.Configuration.publishing.type == .micropub {
                var photos : [String] = []
                var photoAltTags : [String] = []
                var videos : [String] = []
                var videoAltTags : [String] = []
                let text = self.sections.first?.text ?? ""

                for media in mediaDictionary.keys {
                    let location = mediaDictionary[media]!

                    if media.type == .image {
                        photos.append(location.path)
                        photoAltTags.append(media.altText)
                    }
                    else {
                        videos.append(location.path)
                        videoAltTags.append(media.altText)
                    }
                }

                self.activeUpload = Snippets.shared.postText(title: title, content: text, isDraft: false, photos: photos, altTags: photoAltTags, videos: videos, videoAltTags: videoAltTags, completion: { (error, remotePath) in
                    DispatchQueue.main.async {
                        self.handleUploadCompletion(error, remotePath)
                    }

                })
            }
            else {
                let string = HTMLBuilder.createHTML(sections: self.sections, mediaPathDictionary: mediaDictionary)
			
                self.activeUpload = Snippets.shared.postHtml(title: title, content: string) { (error, remotePath) in
                    DispatchQueue.main.async {
                        self.handleUploadCompletion(error, remotePath)
                    }
                }
            }
        }
	}

	func uploadMedia(_ completion : @escaping ([SunlitMedia : MediaLocation]) -> Void) {
		var uploadQueue : [SunlitMedia] = []
		for composition in self.sections {
			for media in composition.media {
				uploadQueue.append(media)
			}
		}
		
		self.mediaUpLoader.uploadMedia(uploadQueue) { (error, dictionary) in

			if let err = error {
                self.handleUploadCompletion(err, nil)
			}
			else {
				completion(dictionary)
			}
		}
	}
	
	func cancelPosting() {

		self.uploading = false
		self.navigationItem.rightBarButtonItem?.isEnabled = true
		self.mediaUpLoader.cancelAll()
		
		if let currentUpload = self.activeUpload {
			currentUpload.cancel()
		}
		
		self.activeUpload = nil
	}
	
	func handleUploadCompletion(_ error : Error?, _ remotePath : String?) {
		
		if let err = error {
            self.cancelPosting()
            
			Dialog(self).information(err.localizedDescription, completion: {
				UIView.animate(withDuration: 0.15) {
					self.disabledInterface.alpha = 0.0
				}
			})
		}
		else {
			let alert = UIAlertController(title: nil, message: "Successfully posted!", preferredStyle: .alert)

            // We can only add this action if we received a valid URL AND it's not in the sharing extension
            if remotePath != nil  && self.extensionContext == nil {
				alert.addAction(UIAlertAction(title: "View Post", style: .default, handler: { (action) in
					self.dismiss(animated: true) {
						NotificationCenter.default.post(name: .openURLNotification, object: remotePath)
					}
				}))
			}
			
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.dismiss(animated: true) {
                    if let extensionContext = self.extensionContext {
                        extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
                    }
                }
			}))
				
			self.present(alert, animated: true, completion: nil)
		}
	}
}






/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.sections.count + 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		// Special case for the "Add new section" button cell...
		if section >= self.sections.count {
			return 1
		}
		
		return self.sections[section].media.count + 2
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		// Special case for the "Add new section" button cell...
		if indexPath.section >= self.sections.count {
			let size = PostAddSectionCollectionViewCell.size(collectionView.bounds.size.width)
			return size
		}
		
		let section = self.sections[indexPath.section]
		if indexPath.item == 0 {
			let size = PostTextCollectionViewCell.size(collectionView.bounds.size.width, section.text)
			return size
		}
		else if indexPath.item > section.media.count {
			let size = PostAddPhotoCollectionViewCell.size(collectionView.bounds.size.width)
			return size
		}
		else {
			let size = PostImageCollectionViewCell.size(collectionView.bounds.size.width)
			return size
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		if section >= self.sections.count {
			// New Section
			return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
		}
		else {
			let horizontalInset = ComposeCollectionViewMetrics.sectionHorizontalInset
			return UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
		}
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		// Special case for the "Add new section" button cell...
		if indexPath.section >= self.sections.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostAddSectionCollectionViewCell", for: indexPath) as! PostAddSectionCollectionViewCell
			return cell
		}
		
		let sectionData = self.sections[indexPath.section]
		
		if indexPath.item == 0 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostTextCollectionViewCell", for: indexPath) as! PostTextCollectionViewCell
			
			// This is sort of an interesting way to tie the data model behind a text view to the UI object
			self.textViewDictionary[cell.postText] = sectionData
			
			cell.postText.text = sectionData.text
			cell.widthConstraint.constant = PostTextCollectionViewCell.size(collectionView.bounds.size.width, sectionData.text).width
			
			// This is somewhat of a hack, however we want the keyboard to be up and the text view to have focus when we very first come into
			// the compose view. This is the simplest/safest way to ensure that there is a "one time" focus activation.
			if indexPath.section == 0 && self.needsInitialFirstResponder {
				self.needsInitialFirstResponder = false
				cell.postText.becomeFirstResponder()
			}
			
			return cell
		}
		else if indexPath.item > sectionData.media.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostAddPhotoCollectionViewCell", for: indexPath) as! PostAddPhotoCollectionViewCell
			let size = PostAddPhotoCollectionViewCell.size(collectionView.bounds.size.width)
			cell.widthConstraint.constant = size.width
			return cell
		}
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostImageCollectionViewCell", for: indexPath) as! PostImageCollectionViewCell
			cell.postImage.image = sectionData.media[indexPath.item - 1].getImage()
			let size = PostImageCollectionViewCell.size(collectionView.bounds.size.width)
			cell.widthConstraint.constant = size.width
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		self.view.endEditing(true)
		
		// Special case for the "Add new section" button cell...
		if indexPath.section >= self.sections.count {
			self.onAddPhoto(indexPath.section)
		}
		else {
			let sectionData = self.sections[indexPath.section]
			if indexPath.item > sectionData.media.count {
				self.onAddPhoto(indexPath.section)
			}
			else if indexPath.item > 0 {
				self.onImageTapped(indexPath.section, indexPath.item - 1)
			}
		}
		
		collectionView.deselectItem(at: indexPath, animated: true)
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
extension ComposeViewController : UICollectionViewDropDelegate, UICollectionViewDragDelegate {

	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

		// A fail safe/defensive coding...
		if indexPath.section >= self.sections.count {
			return []
		}
		
		let section = self.sections[indexPath.section]
		
		// Another fail safe...
		if indexPath.item > section.media.count {
			return []
		}

        if indexPath.item == 0 {
            return []
        }
        
		let media = section.media[indexPath.item - 1]
		let itemProvider = NSItemProvider(object: media.getImage())
		let dragItem = UIDragItem(itemProvider: itemProvider)
		
		return [dragItem]
	}


	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {

		if let destination = destinationIndexPath {

			// Check to see if it's being dragged to an uncreated section (at the bottom)
			if destination.section >= self.sections.count {
				let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
				return proposal
			}
			
			// Check to see if it's being dragged to the title section or to the "add photo" button and deny it...
			let section = self.sections[destination.section]
			if destination.item > section.media.count || destination.item == 0 {
				let proposal = UICollectionViewDropProposal(operation: .forbidden)
				return proposal
			}
			
			// Otherwise, we are good to move it...
			let intent : UICollectionViewDropProposal.Intent = .insertAtDestinationIndexPath
			
			let proposal = UICollectionViewDropProposal(operation: .move, intent: intent)
			return proposal
		}
		else {
			let proposal = UICollectionViewDropProposal(operation: .forbidden)
			return proposal
		}
	}

	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		
		if let destinationIndexPath = coordinator.destinationIndexPath,
		   let drop = coordinator.items.first,
		   let sourceIndexPath = drop.sourceIndexPath{

			// Find and remove the image from the source section...
			let mediaIndex = sourceIndexPath.item - 1
			let sourceSection = self.sections[sourceIndexPath.section]
			let media = sourceSection.media[mediaIndex]
			sourceSection.media.remove(at: mediaIndex)

			// Do we need to delete this section?
			let sectionNeedsDelete = sourceSection.media.count == 0
			var sectionNeedsInsert = false
			
			// If the destination is less than the total, it just means we are moving it to a different section...
			if destinationIndexPath.section < self.sections.count {
				let destSection = self.sections[destinationIndexPath.section]
				destSection.media.insert(media, at: destinationIndexPath.item - 1)
			}
			else {
				// If we are here, it's being move to a destination that doesn't yet exist...
				let section = SunlitComposition()
				section.text = ""
				section.media.append(media)
				self.sections.append(section)
				sectionNeedsInsert = true
			}
			
			
			// Setup the index paths for the collection view updates...
			var sectionToInsert : IndexSet? = nil
			var sectionToDelete : IndexSet? = nil
			var insertItems : [IndexPath] = [destinationIndexPath]
			var deleteItems : [IndexPath] = [sourceIndexPath]

			let sourceSectionIndex = sourceIndexPath.section
			var destSectionIndex = destinationIndexPath.section
			let deleteSectionIndex = sourceSectionIndex
			var insertSectionIndex = destSectionIndex

			if sectionNeedsDelete {
				
				// Do we need to reduce the indexes?
				if sourceSectionIndex < destSectionIndex {
					destSectionIndex = destSectionIndex - 1
					insertSectionIndex = insertSectionIndex - 1
				}

				self.sections.remove(at: sourceIndexPath.section)
				
				sectionToDelete = NSIndexSet(index: deleteSectionIndex) as IndexSet
				deleteItems.removeAll()
				insertItems.removeAll()
				insertItems.append(IndexPath(item: destinationIndexPath.item, section: destSectionIndex))
			}
			
			if sectionNeedsInsert {
				sectionToInsert = NSIndexSet(index: insertSectionIndex) as IndexSet
			}
			
	
			// Update the collection view in a batch update so it looks smooth...
			self.collectionView.performBatchUpdates({

				if let deleteSection = sectionToDelete {
					self.collectionView.deleteSections(deleteSection)
				}
				
				if let insertSection = sectionToInsert {
					self.collectionView.insertSections(insertSection)
				}
				
				if insertItems.count > 0 {
					self.collectionView.insertItems(at: insertItems)
				}
				
				if deleteItems.count > 0 {
					self.collectionView.deleteItems(at: deleteItems)
				}
			})
			{ (complete) in
			}
			
		}
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		
	}
	
	func textViewDidChange(_ textView: UITextView) {
		if let sectionData = self.textViewDictionary[textView] {
			sectionData.text = textView.text
		}

		UIView.performWithoutAnimation {
			self.collectionView.collectionViewLayout.invalidateLayout()
			self.collectionView.layoutIfNeeded()
		}
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: - PHPickerViewControllerDelegate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

@available(iOS 14, *)
extension ComposeViewController : PHPickerViewControllerDelegate {

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        var providers : [NSItemProvider] = []
        for result in results {
            providers.append(result.itemProvider)
        }

        let processor = ItemProviderProcessor { mediaList, mediaDescription in
            if mediaList.count > 0 {
                for media in mediaList {
					self.addMedia(media, mediaDescription)
                }
            }

			self.titleField.text = mediaDescription
            picker.dismiss(animated: true, completion: nil)
        }

        processor.process(providers)
    }
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: - UIImagePickerControllerDelegate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
		if let image = info[.editedImage] as? UIImage {
			let media = SunlitMedia(withImage: image)
			self.addMedia(media, "")
		}
		else if let image = info[.originalImage] as? UIImage {
			let media = SunlitMedia(withImage: image)
			self.addMedia(media, "")
		}
		else if let video = info[.mediaURL] as? URL {
			let media = SunlitMedia(withVideo: video)
			self.addMedia(media, "")
		}
		
		picker.dismiss(animated: true) {
			
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: nil)
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: - CropViewControllerDelegate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : CropViewControllerDelegate {
    
	func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
		if let media = self.croppingMedia {
			media.image = cropped
		}
		
		cropViewController.dismiss(animated: true) {
			self.collectionView.reloadData()
		}
	}
	
	func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
		cropViewController.dismiss(animated: true, completion: nil)
	}
	
	func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
		cropViewController.dismiss(animated: true, completion: nil)
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: - App Extension
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


extension ComposeViewController {

    func setupAppExtensionElements() {
        if let context = self.extensionContext {
            var items : [NSItemProvider] = []
            for item in context.inputItems {
                if let extensionItem = item as? NSExtensionItem {
                    if let attachments = extensionItem.attachments {
                        for itemProvider in attachments {
                            items.append(itemProvider)
                        }
                    }
                }
            }

            if items.count > 0 {
                let processor = ItemProviderProcessor { mediaObjects, mediaDescription in
                    for media in mediaObjects {
						self.addMedia(media, mediaDescription)
                    }
                }

                processor.process(items)
            }
        }

    }
}
