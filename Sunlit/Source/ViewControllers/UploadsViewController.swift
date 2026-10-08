//
//  UploadsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwiftCore
import Snippets

protocol UploadsPickerControllerDelegate : NSObject {
    func imagePickerController(_ picker: UploadsViewController, didFinishPickingMediaWithInfo info: [SunlitMedia])
    func imagePickerControllerDidCancel(_ picker: UploadsViewController)
}

class UploadsViewController: UIViewController {

    var delegate : UploadsPickerControllerDelegate? = nil

    @IBOutlet var collectionView : UICollectionView!
    @IBOutlet var busyIndicator : UIActivityIndicatorView!

    var media : [ [String : Any] ] = []
    private var selectionGeneration = 0
    private var resolvingSelection = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigation()
        self.setupNotifications()
        self.setupCollectionView()
        self.loadMedia()
    }

    func setupNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
    }

    func setupCollectionView() {
        self.collectionView.allowsMultipleSelection = true
    }

    @objc func onCancel() {
        self.selectionGeneration += 1
        self.resolvingSelection = false
        self.dismiss(animated: true) {
            if let delegate = self.delegate {
                delegate.imagePickerControllerDidCancel(self)
            }
        }
    }

    @objc func onDone() {
        guard !self.resolvingSelection else { return }
        let indexes = (self.collectionView.indexPathsForSelectedItems ?? []).sorted { $0.item < $1.item }
        let paths = indexes.compactMap { index -> String? in
            guard self.media.indices.contains(index.item) else { return nil }
            return self.media[index.item]["url"] as? String
        }
        self.selectionGeneration += 1
        self.resolvingSelection = true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.collectionView.isUserInteractionEnabled = false
        self.busyIndicator.isHidden = false
        self.busyIndicator.startAnimating()
        self.loadSelectedMedia(paths, index: 0, selectedMedia: [], generation: self.selectionGeneration)
    }

    private func loadSelectedMedia(_ paths: [String], index: Int, selectedMedia: [SunlitMedia], generation: Int) {
        guard self.resolvingSelection, generation == self.selectionGeneration else { return }
        guard index < paths.count else {
            self.finishResolvingSelection()
            self.delegate?.imagePickerController(self, didFinishPickingMediaWithInfo: selectedMedia)
            return
        }

        let path = paths[index]
        let thumbnailPath = self.thumbnailForPath(path)
        let acceptImage: (UIImage?) -> Void = { [weak self] image in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.resolvingSelection, generation == self.selectionGeneration else { return }
                guard let image = image, image.size.width > 1, image.size.height > 1 else {
                    self.finishResolvingSelection()
                    Dialog(self).information("Unable to download the selected photo. Check your internet connection and try again.")
                    return
                }
                let media = SunlitMedia(withImage: image)
                media.publishedPath = path
                media.thumbnailPath = thumbnailPath
                self.loadSelectedMedia(paths, index: index + 1, selectedMedia: selectedMedia + [media], generation: generation)
            }
        }

        ImageCache.fetch(thumbnailPath) { image in
            if let image = image, image.size.width > 1, image.size.height > 1 {
                acceptImage(image)
            }
            else {
                ImageCache.fetch(path, completion: acceptImage)
            }
        }
    }

    private func finishResolvingSelection() {
        self.resolvingSelection = false
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.collectionView.isUserInteractionEnabled = true
        self.busyIndicator.stopAnimating()
        self.busyIndicator.isHidden = true
    }

    @objc func handleImageLoadedNotification(_ notification : Notification) {

		DispatchQueue.main.async {
			if let userInfo = notification.userInfo,
			   let indexPath = userInfo["index"] as? IndexPath {

				let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
                if visibleIndexPaths.contains(indexPath) {
                    self.collectionView.reloadData()
                }
            }
        }
    }

    func loadMedia() {

        self.busyIndicator.isHidden = false
        self.busyIndicator.startAnimating()

        _ = Snippets.Micropub.fetchPublishedMedia(BlogSettings.blogForPublishing().snippetsConfiguration!, completion: { (error, items) in
            DispatchQueue.main.async {
                self.busyIndicator.stopAnimating()
                self.busyIndicator.isHidden = true
                if let items = items {
                    self.media = items
                    self.collectionView.reloadData()
                }
                else if let error = error {
                    Dialog(self).information(error.localizedDescription)
                }
            }
        })

    }

    func isSupportedMediaType(_ index : Int) -> Bool {
        let item = self.media[index]
        if let url = item["url"] as? String {
            if url.hasSuffix(".png") || url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") || url.hasSuffix(".gif") {
                return true
            }
        }

        return false
    }

    func iconForMediaType(_ index : Int) -> UIImage? {
        let item = self.media[index]
        if let url = item["url"] as? String {
            if url.hasSuffix(".png") || url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") || url.hasSuffix(".gif") {
                return UIImage(systemName: "doc")
            }
            else if url.hasSuffix(".mov") || url.hasSuffix(".m4v") || url.hasSuffix(".mp4"){
                return UIImage(systemName: "film")
            }
            else if url.hasSuffix("mp3") || url.hasSuffix("m4a") {
                return UIImage(systemName: "waveform")
            }
        }

        return UIImage(systemName: "icloud.slash")
    }

    func thumbnailForPath(_ path : String) -> String {

        let fullPath = "https://micro.blog/photos/200/" + path
        return fullPath
    }


    func loadPhoto(_ originalPath : String,  _ index : IndexPath) {

        let path = thumbnailForPath(originalPath)

        // If the photo exists, bail!
        if ImageCache.prefetch(path) != nil {
            return
        }

        ImageCache.fetch(path) { (image) in

            if let img = image {

                // Currently, the Micro.blog server always returns a 1x1 pixel if the
                // thumbnail doesn't exist. So, we need to skip over it...
                if img.size.width <= 1 || img.size.height <= 1 {
                    return
                }

                DispatchQueue.main.async {
                    self.collectionView.performBatchUpdates({
                        self.collectionView.reloadItems(at: [ index ])
                    }, completion: nil)
                }
            }
        }
    }


}

extension UploadsViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.isSupportedMediaType(indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.media.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return PhotoEntryCollectionViewCell.sizeOf(collectionViewWidth: collectionView.bounds.size.width)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item < self.media.count {
            let post = self.media[indexPath.item]
            self.loadPhoto(post["url"] as! String, indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let post = self.media[indexPath.item]
            self.loadPhoto(post["url"] as! String, indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath) as! PhotoEntryCollectionViewCell
        let item = media[indexPath.item]
        if let url = item["url"] as? String,
           let date = item["published"] as? String {
			
            if let rawDate = date.uuParseDate(format: "yyyy-MM-dd'T'HH:mm:ss+00:00") {
				cell.date.text = rawDate.uuFormat(UUDate.Formats.iso8601DateOnly)
            }
            else {
                cell.date.text = date
            }

            cell.photo.contentMode = .center
            cell.photo.image = self.iconForMediaType(indexPath.item)

            let path = thumbnailForPath(url)
            if let image = ImageCache.prefetch(path) {

                // Currently, the Micro.blog server always returns a 1x1 pixel if the
                // thumbnail doesn't exist. So, we need to skip over it...
                if image.size.width > 1 && image.size.height > 1 {
                    cell.photo.contentMode = .scaleAspectFill
                    cell.photo.image = image
                }
            }
        }

        return cell
    }


}
