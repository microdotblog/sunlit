//
//  ComposeViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SunlitStorySection {
	var text = ""
	var images : [UIImage] = []
}


class ComposeViewController: UIViewController {

	@IBOutlet var collectionView : UICollectionView!
	var sections : [SunlitStorySection] = []
	var needsInitialFirstResponder = true
	var sectionToAddImage = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
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
		let rightItems : [UIBarButtonItem] = [UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost)) ,
											  /*UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddPhoto))*/ ]
		self.navigationItem.rightBarButtonItems = rightItems
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
	}
    
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func onAddPhoto(_ section : Int) {
		self.sectionToAddImage = section
		
		let pickerController = UIImagePickerController()
		pickerController.delegate = self
		pickerController.allowsEditing = true
		pickerController.mediaTypes = ["public.image", "public.movie"]
		pickerController.sourceType = .photoLibrary
		self.present(pickerController, animated: true, completion: nil)
	}

	@objc func onPost() {
		
	}
	
	@objc func onCancel() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	func addImage(_ image : UIImage) {
		if self.sectionToAddImage >= self.sections.count {
			let section = SunlitStorySection()
			section.text = ""
			section.images.append(image)
			self.sections.append(section)
		}
		else {
			let section = self.sections[self.sectionToAddImage]
			section.images.append(image)
		}

		if self.collectionView != nil {
			self.collectionView.reloadData()
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
		
		return self.sections[section].images.count + 2
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
		else if indexPath.item > section.images.count {
			let size = PostImageCollectionViewCell.size(collectionView.bounds.size.width)
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
			return cell
		}
		
		let sectionData = self.sections[indexPath.section]
		
		if indexPath.item == 0 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostTextCollectionViewCell", for: indexPath) as! PostTextCollectionViewCell
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
		else if indexPath.item > sectionData.images.count {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostAddPhotoCollectionViewCell", for: indexPath) as! PostAddPhotoCollectionViewCell
			return cell
		}
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostImageCollectionViewCell", for: indexPath) as! PostImageCollectionViewCell
			cell.postImage.image = sectionData.images[indexPath.item - 1]
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
			if indexPath.item > sectionData.images.count {
				self.onAddPhoto(indexPath.section)
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
		let section = self.sections[indexPath.section]
		let image = section.images[indexPath.item - 1]
		let itemProvider = NSItemProvider(object: image)
		let dragItem = UIDragItem(itemProvider: itemProvider)
		
		return [dragItem]
	}


	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		
		if let destination = destinationIndexPath {
			
			// Check to see if it's being dragged to an uncreated section (at the bottom)
			if destination.section >= self.sections.count {
				let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
				return proposal
			}
			
			// Check to see if it's being dragged to the title section or to the "add photo" button and deny it...
			let section = self.sections[destination.section]
			if destination.item > section.images.count || destination.item == 0 {
				let proposal = UICollectionViewDropProposal(operation: .forbidden)
				return proposal
			}
			
			// Otherwise, we are good to move it...
			let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
			return proposal
		}
		else {
			// For now, we aren't going to support deleting from here...
			let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
			return proposal
		}
	}

	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		if let destinationIndexPath = coordinator.destinationIndexPath,
		   let drop = coordinator.items.first,
		   let sourceIndexPath = drop.sourceIndexPath{
			
			let sourceSection = self.sections[sourceIndexPath.section]
			let image = sourceSection.images[sourceIndexPath.item - 1]
			sourceSection.images.remove(at: sourceIndexPath.item - 1)
			
			let deleteSection = sourceSection.images.count == 0
			var insertSection = false
			
			if destinationIndexPath.section < self.sections.count {
				let destSection = self.sections[destinationIndexPath.section]
				destSection.images.insert(image, at: destinationIndexPath.item - 1)
			}
			else {
				let section = SunlitStorySection()
				section.text = ""
				section.images.append(image)
				self.sections.append(section)
				insertSection = true
			}
			
			let insertItems = [destinationIndexPath]
			let deleteItems = [sourceIndexPath]
			
			if deleteSection {
				self.sections.remove(at: sourceIndexPath.section)
			}
			
			self.collectionView.performBatchUpdates({
				
				if deleteSection {
					let destIndexPath = IndexPath(item: destinationIndexPath.item, section: destinationIndexPath.section - 1)
					self.collectionView.deleteSections(NSIndexSet(index: sourceIndexPath.section) as IndexSet)
					if insertSection {
						self.collectionView.insertSections(NSIndexSet(index: destIndexPath.section) as IndexSet)
					}
					
					self.collectionView.insertItems(at: [destIndexPath])
				}
				else {
					self.collectionView.deleteItems(at: deleteItems)
					self.collectionView.insertItems(at: insertItems)
				}
			})
			{ (complete) in
			}
			
		}
	}
	
	
	/*
	
	- (void) collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(id<UICollectionViewDropCoordinator>)coordinator
	{
		NSIndexPath* destinationIndexPath = coordinator.destinationIndexPath;
	  
		id<UICollectionViewDropItem> drop = [coordinator.items firstObject];
		UIDragItem* item = drop.dragItem;
		
		SLEntry* dragged_e = item.localObject;
		
		NSIndexSet* deleting_section = [self.story removeEntry:dragged_e];
		if (deleting_section)
		{
			NSUInteger removedSection = deleting_section.firstIndex;
			
			if (removedSection < destinationIndexPath.section)
			{
				destinationIndexPath = [NSIndexPath indexPathForItem:destinationIndexPath.item inSection:destinationIndexPath.section - 1];
			}
		}
		
		[self.story move:dragged_e to:destinationIndexPath];
		
		[self.entriesCollectionView performBatchUpdates:^{
			if (deleting_section) {
				[self.entriesCollectionView deleteSections:deleting_section];
			}
			else {
				[self.entriesCollectionView deleteItemsAtIndexPaths:@[ drop.sourceIndexPath ]];
			}
			[self.entriesCollectionView insertItemsAtIndexPaths:@[ destinationIndexPath ]];
		}
		completion:^(BOOL finished)
		{
		}];

	}


	*/
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension ComposeViewController : UITextViewDelegate {
	
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
			self.addImage(image)
		}
		
		picker.dismiss(animated: true) {
			
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.navigationController?.dismiss(animated: true, completion: {
		})
	}
	
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class PostImageCollectionViewCell : UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		let size : CGFloat = (collectionViewWidth / 3.0)
		return CGSize(width: size, height: size)
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class PostTextCollectionViewCell : UICollectionViewCell {
	@IBOutlet var postText : UITextView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func size(_ collectionViewWidth : CGFloat, _ text : String) -> CGSize {
		var size = CGSize(width: collectionViewWidth - 16.0, height: 0)
		let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin , context: nil)
		size.height = rect.size.height
		size.height = size.height + 32.0
		size.width = collectionViewWidth - 8.0
		if size.height < 60.0 {
			size.height = 60.0
		}
		return size
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

class PostAddPhotoCollectionViewCell : UICollectionViewCell {
}
