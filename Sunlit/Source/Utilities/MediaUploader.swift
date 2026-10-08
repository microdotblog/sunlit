//
//  MediaUploader.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwiftNetworking

class MediaLocation : NSObject {
	var path : String = ""
	var thumbnailPath : String = ""
}

class MediaUploader {

    static let maxUploads = 4

    // All upload state, including pending transcodes, belongs to this queue.
    private let queue = DispatchQueue(label: "io.sunlit.media-uploader", qos: .userInitiated)
    private var generation = 0
    private var mediaQueue: [SunlitMedia] = []
    private var results: [SunlitMedia: MediaLocation] = [:]
    private var completion: ((Error?, [SunlitMedia: MediaLocation]) -> Void)?
    private var currentUploads: [SunlitMedia: UUHttpRequest] = [:]
    private var activeMediaCount = 0

    func cancelAll() {
        self.queue.async {
            self.reset()
        }
    }

    func uploadMedia(_ media: [SunlitMedia], completion: @escaping (Error?, [SunlitMedia: MediaLocation]) -> Void) {
        self.queue.async {
            self.reset()
            self.completion = completion
            self.mediaQueue = media
            self.processUploadQueue()
        }
    }

    private func reset() {
        self.generation += 1
        self.completion = nil
        self.mediaQueue.removeAll()
        self.results.removeAll()
        self.activeMediaCount = 0
        let uploads = Array(self.currentUploads.values)
        self.currentUploads.removeAll()
        for upload in uploads {
            upload.cancel()
        }
    }

    private func finish(_ error: Error?) {
        guard let completion = self.completion else { return }
        let results = self.results
        self.reset()
        DispatchQueue.main.async {
            completion(error, results)
        }
    }

    private func uploadError(_ message: String) -> Error {
        return NSError(domain: "Sunlit.MediaUploader", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func processUploadQueue() {
        while !self.mediaQueue.isEmpty && self.activeMediaCount < Self.maxUploads {
            let media = self.mediaQueue.removeFirst()
            if let path = media.publishedPath, let thumbnailPath = media.thumbnailPath {
                self.recordLocation(media, path: path, thumbnailPath: thumbnailPath)
                continue
            }

            self.activeMediaCount += 1
            let generation = self.generation
            if media.type == .image {
                self.uploadImage(media, generation: generation)
            }
            else {
                VideoTranscoder.exportVideo(sourceUrl: media.videoURL) { [weak self] error, videoURL in
                    guard let self = self else { return }
                    self.queue.async {
                        guard generation == self.generation else { return }
                        if let error = error {
                            self.finish(error)
                            return
                        }
                        do {
                            let data = try Data(contentsOf: videoURL)
                            self.uploadVideo(media, data, generation: generation)
                        }
                        catch {
                            self.finish(error)
                        }
                    }
                }
            }
        }

        if self.mediaQueue.isEmpty && self.activeMediaCount == 0 {
            self.finish(nil)
        }
    }

    private func recordLocation(_ media: SunlitMedia, path: String, thumbnailPath: String) {
        media.publishedPath = path
        media.thumbnailPath = thumbnailPath
        let location = MediaLocation()
        location.path = path
        location.thumbnailPath = thumbnailPath
        self.results[media] = location
    }

    private func dataUploaded(_ media: SunlitMedia, error: Error?, path: String?, thumbnailPath: String?) {
        self.currentUploads.removeValue(forKey: media)
        if let error = error {
            self.finish(error)
            return
        }
        guard let path = path, let thumbnailPath = thumbnailPath else {
            self.finish(self.uploadError("The server did not return a URL for the uploaded media."))
            return
        }
        self.recordLocation(media, path: path, thumbnailPath: thumbnailPath)
        self.activeMediaCount -= 1
        self.processUploadQueue()
    }

    private func uploadImage(_ media: SunlitMedia, generation: Int) {
        let type: SnippetsImageFileType = media.fileType == "public.png" ? .png : .jpeg
        let upload = Snippets.shared.uploadImage(image: SnippetsImage(media.getImage(), type: type)) { [weak self] error, path in
            guard let self = self else { return }
            self.queue.async {
                guard generation == self.generation else { return }
                let thumbnailPath = path.map { "https://micro.blog/photos/200/" + $0 }
                self.dataUploaded(media, error: error, path: path, thumbnailPath: thumbnailPath)
            }
        }
        if let upload = upload {
            self.currentUploads[media] = upload
        }
        else {
            self.finish(self.uploadError("Unable to start the image upload. Check your blog's publishing settings."))
        }
    }

    private func uploadVideo(_ media: SunlitMedia, _ data: Data, generation: Int) {
        let upload = Snippets.shared.uploadVideo(data: data) { [weak self] error, path, thumbnailPath in
            guard let self = self else { return }
            self.queue.async {
                guard generation == self.generation else { return }
                self.dataUploaded(media, error: error, path: path, thumbnailPath: thumbnailPath)
            }
        }
        if let upload = upload {
            self.currentUploads[media] = upload
        }
        else {
            self.finish(self.uploadError("Unable to start the video upload. Check that your blog supports video publishing."))
        }
    }
}
