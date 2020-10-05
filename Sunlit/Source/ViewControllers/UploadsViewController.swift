//
//  UploadsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwift
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
        self.dismiss(animated: true) {
            if let delegate = self.delegate {
                delegate.imagePickerControllerDidCancel(self)
            }
        }
    }

    @objc func onDone() {

        var selectedMedia : [SunlitMedia] = []

        if let indexes = self.collectionView.indexPathsForSelectedItems {
            for index in indexes {
                let dictionary = self.media[index.item]
                let remotePath = dictionary["url"] as! String
                let image = ImageCache.prefetch(self.thumbnailForPath(remotePath))!
                let media = SunlitMedia(withImage: image)
                media.publishedPath = remotePath
                media.thumbnailPath = self.thumbnailForPath(remotePath)
                selectedMedia.append(media)
            }
        }

        DispatchQueue.main.async {
            if let delegate = self.delegate {
                delegate.imagePickerController(self, didFinishPickingMediaWithInfo: selectedMedia)
            }
        }
    }

    @objc func handleImageLoadedNotification(_ notification : Notification) {
        DispatchQueue.main.async {
            if let indexPath = notification.object as? IndexPath {
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

        let fullPath : NSString = Snippets.Configuration.publishing.micropubMediaEndpoint as NSString
        let arguments : [ String : String ] = [ "q" : "source" ]

        let request = Snippets.secureGet(Snippets.Configuration.publishing, path: fullPath as String, arguments: arguments)

        _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
            if let dictionary = parsedServerResponse.parsedResponse as? [String : Any] {
                if let items = dictionary["items"] as? [ [String : Any] ] {
                    self.media = items
                    DispatchQueue.main.async {
                        self.busyIndicator.isHidden = true
                        self.collectionView.reloadData()
                    }
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

        ImageCache.fetch(self, path) { (image) in

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

            if let rawDate = date.uuParseDate(format: UUDate.Formats.rfc3339) {
                cell.date.text = rawDate.friendlyFormat()
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
