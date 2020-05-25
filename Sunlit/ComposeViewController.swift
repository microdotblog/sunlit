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


class ComposeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout {

	@IBOutlet var collectionView : UICollectionView!
	var sections : [SunlitStorySection] = []
	var needsInitialFirstResponder = true
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			flowLayout.estimatedItemSize = CGSize(width: self.view.bounds.size.width / 3.0, height:  self.view.bounds.size.width / 3.0)
			flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		}
		self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		
		self.navigationItem.title = "New Post"
		let rightItems : [UIBarButtonItem] = [UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost)) ,
											  /*UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddPhoto))*/ ]
		self.navigationItem.rightBarButtonItems = rightItems
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
    
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@objc func onAddPhoto() {
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
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func addImage(_ image : UIImage) {
		if self.sections.count == 0 {
			let section = SunlitStorySection()
			section.text = ""
			section.images.append(image)
			self.sections.append(section)
		}
		else if let section = self.sections.last {
			section.images.append(image)
		}

		if self.collectionView != nil {
			self.collectionView.reloadData()
		}
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.sections.count
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.sections[section].images.count + 2
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

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
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
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
		let sectionData = self.sections[indexPath.section]
		if indexPath.item > sectionData.images.count {
			self.onAddPhoto()
		}
		
		collectionView.deselectItem(at: indexPath, animated: true)
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		
	}
	
}

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

class PostImageCollectionViewCell : UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		let size : CGFloat = (collectionViewWidth / 3.0)
		return CGSize(width: size, height: size)
	}
}

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

class PostAddPhotoCollectionViewCell : UICollectionViewCell {
}
