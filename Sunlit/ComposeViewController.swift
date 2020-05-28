//
//  ComposeViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ComposeViewController: UIViewController {

	@IBOutlet var titleField : UITextField!
	@IBOutlet var titleHeightConstraint : NSLayoutConstraint!
	@IBOutlet var disabledInterface : UIView!
	@IBOutlet var collectionView : UICollectionView!
	var sections : [SunlitComposition] = []
	var textViewDictionary : [UITextView : SunlitComposition] = [ : ]
	var needsInitialFirstResponder = true
	var sectionToAddMedia = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.bringSubviewToFront(self.disabledInterface)
		self.titleHeightConstraint.constant = 0.0
		
		self.configureCollectionView()
		self.configureNavigationController()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	func configureCollectionView() {
		if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			flowLayout.estimatedItemSize = CGSize(width: self.view.bounds.size.width / 3.0, height:  self.view.bounds.size.width / 3.0)
			flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		}
		self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		self.collectionView.dragInteractionEnabled = true
	}
	
	func configureNavigationController() {
		self.navigationItem.title = "New Post"
		let rightItems : [UIBarButtonItem] = [UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost)) ]
		self.navigationItem.rightBarButtonItems = rightItems
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		.darkContent
	}
    
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func addMedia(_ media : SunlitMedia) {
		if self.sectionToAddMedia >= self.sections.count {
			let section = SunlitComposition()
			section.text = ""
			section.media.append(media)
			section.altText.append("")
			self.sections.append(section)
		}
		else {
			let section = self.sections[self.sectionToAddMedia]
			section.media.append(media)
			section.altText.append("")
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

		let sectionData = self.sections[section]

		var editTextTitle = "Add Alt Text"
		if sectionData.altText[item].count > 0 {
			editTextTitle = "Edit Alt Text"
		}
		
		let altTextAction = UIAlertAction(title: editTextTitle, style: .default) { (action) in
			self.onEditAltText(sectionData, item)
		}

		let deleteAction = UIAlertAction(title: "Remove", style: .default) { (action) in
			self.onRemoveImage(sectionData, item: item, section: section)
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
		}
		
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alertController.addAction(deleteAction)
		alertController.addAction(altTextAction)
		alertController.addAction(cancelAction)
		
		self.present(alertController, animated: true, completion: nil)
	}
	
	@objc func onAddPhoto(_ section : Int) {
		self.sectionToAddMedia = section
		
		let pickerController = UIImagePickerController()
		pickerController.delegate = self
		pickerController.mediaTypes = ["public.image", "public.movie"]
		pickerController.sourceType = .savedPhotosAlbum
		pickerController.allowsEditing = false
		self.present(pickerController, animated: true, completion: nil)
	}

	@objc func onPost() {
		
		// Force the keyboard to go away...
		self.view.endEditing(true)
		
		UIView.animate(withDuration: 0.15) {
			self.disabledInterface.alpha = 1.0
		}
		self.uploadComposition()
	}
	
	@objc func onCancel() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}

	func onRemoveImage(_ sectionData : SunlitComposition, item : Int, section : Int) {
		sectionData.media.remove(at: item)
		sectionData.altText.remove(at: item)
		
		if sectionData.media.count == 0 {
			self.sections.remove(at: section)
		}
		
		self.collectionView.reloadData()
	}
	
	func onEditAltText(_ section : SunlitComposition, _ item : Int) {
		
		let currentAltText = section.altText[item]
		var alertTextField : UITextField? = nil
		let alertController = UIAlertController(title: "Accessibility Description", message: nil, preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.text = currentAltText
			textField.autocorrectionType = .yes
			textField.keyboardType = .asciiCapable
			textField.autocapitalizationType = .sentences
			alertTextField = textField
		}

		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
		}

		var saveTitle = "Add"
		if currentAltText.count > 0 {
			saveTitle = "Update"
		}

		let update = UIAlertAction(title: saveTitle, style: .default) { (action) in
			let altText : String = alertTextField?.text ?? ""
			section.altText[item] = altText
		}
		
		alertController.addAction(update)
		alertController.addAction(cancel)
		
		self.present(alertController, animated: true, completion: nil)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func uploadComposition() {
		let title : String = self.titleField.text ?? ""
		self.uploadMedia { (mediaDictionary : [SunlitMedia : MediaLocation]) in
			let string = HTMLBuilder.createHTML(sections: self.sections, mediaPathDictionary: mediaDictionary)
			Snippets.shared.postHtml(title: title, content: string) { (error, remotePath) in
				DispatchQueue.main.async {
					self.handleUploadCompletion(error, remotePath)
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
		
		let mediaUpLoader = MediaUploader()
		mediaUpLoader.uploadMedia(uploadQueue) { (error, dictionary) in

			if let err = error {
				Dialog.information(err.localizedDescription, self)
			}
			else {
				completion(dictionary)
			}
		}
	}
	
	func handleUploadCompletion(_ error : Error?, _ remotePath : String?) {
		
		if let err = error {
			Dialog.information(err.localizedDescription, self, completion: {
				UIView.animate(withDuration: 0.15) {
					self.disabledInterface.alpha = 0.0
				}
			})
		}
		else {
			let alert = UIAlertController(title: nil, message: "Successfully posted!", preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(title: "View Post", style: .default, handler: { (action) in
				self.dismiss(animated: true) {
					NotificationCenter.default.post(name: NSNotification.Name("OpenURLNotification"), object: remotePath)
				}
			}))
				
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
				self.dismiss(animated: true, completion: nil)
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
			return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		}
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		// Special case for the "Add new section" button cell...
		if indexPath.section >= self.sections.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostAddSectionCollectionViewCell", for: indexPath) as! PostAddSectionCollectionViewCell
			cell.widthConstraint.constant = collectionView.bounds.size.width - 24
			return cell
		}
		
		let sectionData = self.sections[indexPath.section]
		
		if indexPath.item == 0 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostTextCollectionViewCell", for: indexPath) as! PostTextCollectionViewCell
			
			// This is sort of an interesting way to tie the data model behind a text view to the UI object
			self.textViewDictionary[cell.postText] = sectionData
			
			cell.postText.text = sectionData.text
			cell.widthConstraint.constant = collectionView.bounds.size.width
			
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
		
		let media = section.media[indexPath.item - 1]
		let itemProvider = NSItemProvider(object: media.getImage())
		let dragItem = UIDragItem(itemProvider: itemProvider)
		
		return [dragItem]
	}


	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		
		if let destination = destinationIndexPath {

			// Check to see if it's being dragged to an uncreated section (at the bottom)
			if destination.section >= self.sections.count {
				//let proposal = UICollectionViewDropProposal(operation: .forbidden)
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
			let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
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
			let altText = sourceSection.altText[mediaIndex]
			sourceSection.media.remove(at: mediaIndex)
			sourceSection.altText.remove(at: mediaIndex)

			// Do we need to delete this section?
			let sectionNeedsDelete = sourceSection.media.count == 0
			var sectionNeedsInsert = false
			
			// If the destination is less than the total, it just means we are moving it to a different section...
			if destinationIndexPath.section < self.sections.count {
				let destSection = self.sections[destinationIndexPath.section]
				destSection.media.insert(media, at: destinationIndexPath.item - 1)
				destSection.altText.insert(altText, at: destinationIndexPath.item - 1)
			}
			else {
				// If we are here, it's being move to a destination that doesn't yet exist...
				let section = SunlitComposition()
				section.text = ""
				section.media.append(media)
				section.altText.append(altText)
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
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
			UIView.setAnimationsEnabled(false)
			self.collectionView.performBatchUpdates({
			}) { (complete) in
			}
			UIView.setAnimationsEnabled(true)
		}
			
		return true
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
		if let image = info[.editedImage] as? UIImage {
			let media = SunlitMedia(withImage: image)
			self.addMedia(media)
		}
		else if let image = info[.originalImage] as? UIImage {
			let media = SunlitMedia(withImage: image)
			self.addMedia(media)
		}
		else if let video = info[.mediaURL] as? URL {
			let media = SunlitMedia(withVideo: video)
			self.addMedia(media)
		}
		
		picker.dismiss(animated: true) {
			
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.navigationController?.dismiss(animated: true, completion: {
		})
	}
	
}

