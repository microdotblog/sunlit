//
//  ItemProviderProcessor.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/23/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import MobileCoreServices

class ItemProviderProcessor : NSObject {

    var providers : [NSItemProvider] = []
    var processedMedia : [SunlitMedia] = []
    var completion : (([SunlitMedia])-> Void)? = nil

    init(_ completion : @escaping ([SunlitMedia]) -> Void) {
        super.init()
        self.completion = completion
    }

    func process(_ providers : [NSItemProvider]) {
        self.providers = providers
        self.processedMedia = []
        self.processNextProvider()
    }

    private func processNextProvider() {

        if self.providers.count <= 0 {
            DispatchQueue.main.async {
                if let completion = self.completion {
                    completion(self.processedMedia)
                }
            }
            return
        }

        let provider = self.providers.removeFirst()
        if provider.canLoadObject(ofClass: UIImage.self) {
            self.processImageProvider(provider)
        }
        else if provider.canLoadObject(ofClass: URL.self) {
            self.processVideoProvider(provider)
        }
        else {
            print("*** Skipping unknown/unhandled item provder ***")
            self.processNextProvider()
        }
    }

    private func processImageProvider(_ provider : NSItemProvider) {

        _ = provider.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
            if let image = image as? UIImage{
                self.processedMedia.append(SunlitMedia(withImage: image))
                self.processNextProvider()
            }
            else {
                provider.loadItem(forTypeIdentifier: String(kUTTypeImage), options: nil) { (object, error) in
                    if let image = object as? UIImage {
                        self.processedMedia.append(SunlitMedia(withImage: image))
                        self.processNextProvider()
                    }
                    else {
                        provider.loadInPlaceFileRepresentation(forTypeIdentifier: String(kUTTypeImage)) { (url, success, error) in
                            if let url = url {
                                if let data = try? Data(contentsOf: url) {
                                    if let image = UIImage(data: data) {
                                        self.processedMedia.append(SunlitMedia(withImage: image))
                                    }
                                }
                            }
                            self.processNextProvider()
                        }
                    }
                }
            }
        })
    }

    private func processVideoProvider(_ provider : NSItemProvider) {

        _ = provider.loadObject(ofClass: URL.self) { (url, error) in
            if let videoURL = url {
                self.processedMedia.append(SunlitMedia(withVideo: videoURL))
            }
            else {
                print("*** Unable to process provider of URL type ***")
            }

            self.processNextProvider()
        }

    }
}
