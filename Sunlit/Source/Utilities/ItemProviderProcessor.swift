//
//  ItemProviderProcessor.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/23/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwiftNetworking
import MobileCoreServices

class ItemProviderProcessor : NSObject {

    var providers : [NSItemProvider] = []
    var processedMedia : [SunlitMedia] = []
	var processedDescription = ""
    var completion : (([SunlitMedia], String)-> Void)? = nil

    init(_ completion : @escaping ([SunlitMedia], String) -> Void) {
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
					completion(self.processedMedia, self.processedDescription)
                }
            }
            return
        }

        let provider = self.providers.removeFirst()

        for registeredType in provider.registeredTypeIdentifiers {

            if registeredType == "public.movie" || registeredType == "com.apple.quicktime-movie" || registeredType == "com.apple.avfoundation.urlasset" {
                self.processVideoProvider(provider)
                return
            }

            if registeredType == "public.image" || registeredType == "public.jpeg" || registeredType == "public.heic" || registeredType == "public.png" || registeredType == "public.gif" {
                self.processImageProvider(provider, registeredType)
                return
            }

            if registeredType == "public.url" {
                self.processURLProvider(provider)
                return
            }

            print("Unknown provider type: \(registeredType)")
        }

    }

	private func specialCaseGlassURL(_ url : URL) {
		UUHttpSession.get(url: url.absoluteString, completion: { response in
			if let responseString = response.parsedResponse as? String {
				let parser = HTMLParser(responseString)
				let images = parser.findImages()
				let description = parser.findGlassDescription()
				self.processedDescription = description
				
				UUHttpSession.get(url: images.first!) { imageResponse in
					if let image = imageResponse.parsedResponse as? UIImage {
						self.processedMedia.append(SunlitMedia(withImage: image))
					}

					self.processNextProvider()
				}
			}
		})
	}

    private func processURLProvider(_ provider : NSItemProvider) {

        _ = provider.loadObject(ofClass: URL.self, completionHandler: { (urlObject, error) in
            if let url = urlObject {

				if url.host == "glass.photo" {
					self.specialCaseGlassURL(url)
					return
				}

                let request = UUHttpRequest(url: url.absoluteString)
                request.processMimeTypes = false

                _ = UUHttpSession.executeRequest(request) { (response) in

                    if let data = response.rawResponse {
                        if let image = UIImage(data: data) {
                            self.processedMedia.append(SunlitMedia(withImage: image))
                        }
                    }

                    // TODO: DO we need to add a text media type here???

                    self.processNextProvider()
                }
            }
            else {
                print("Unable to load URL object")
                self.processNextProvider()
            }
        })
    }

	private func processImageProvider(_ provider : NSItemProvider, _ type : String) {

        _ = provider.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
            if let image = image as? UIImage{
                self.processedMedia.append(SunlitMedia(withImage: image, fileType: type))
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

        _ = provider.loadInPlaceFileRepresentation(forTypeIdentifier: String(kUTTypeMovie), completionHandler: { (url, success, error) in
            if let videoURL = url {
                self.processedMedia.append(SunlitMedia(withVideo: videoURL))
            }
            else {
                print("*** Unable to process provider of URL type ***")
            }

            self.processNextProvider()

        })

    }
}
