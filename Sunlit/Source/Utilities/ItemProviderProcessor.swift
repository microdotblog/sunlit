//
//  ItemProviderProcessor.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/23/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVKit
import PhotosUI
import Snippets
import UUSwiftNetworking
import MobileCoreServices

class ItemProviderProcessor : NSObject {

    var providers : [NSItemProvider] = []
    var processedMedia : [SunlitMedia] = []
	var processedDescription = ""
    var completion : (([SunlitMedia], String, Error?)-> Void)? = nil
    private var processingError: Error?

    init(_ completion : @escaping ([SunlitMedia], String, Error?) -> Void) {
        super.init()
        self.completion = completion
    }

    func process(_ providers : [NSItemProvider]) {
        self.providers = providers
        self.processedMedia = []
        self.processedDescription = ""
        self.processingError = nil
        self.processNextProvider()
    }

    private func processNextProvider() {

        if self.providers.count <= 0 {
            DispatchQueue.main.async {
                if let completion = self.completion {
                    self.completion = nil
					completion(self.processedMedia, self.processedDescription, self.processingError)
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
        self.providerFailed(nil)
    }

    private func providerFailed(_ error: Error?) {
        DispatchQueue.main.async {
            self.processingError = error ?? NSError(domain: "Sunlit.MediaImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to import one of the selected items. Please try selecting it again."])
            self.processNextProvider()
        }
    }

	private func specialCaseGlassURL(_ url : URL) {
		UUHttpSession.get(url: url.absoluteString, completion: { response in
			if let responseString = response.parsedResponse as? String {
				let parser = HTMLParser(responseString)
				let images = parser.findImages()
				let description = parser.findGlassDescription()
				self.processedDescription = description
				
				guard let imagePath = images.first else {
					self.providerFailed(nil)
					return
				}
				UUHttpSession.get(url: imagePath) { imageResponse in
					if let image = imageResponse.parsedResponse as? UIImage {
						self.processedMedia.append(SunlitMedia(withImage: image))
					}

					self.processNextProvider()
				}
			}
			else {
				self.providerFailed(nil)
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
                //request.processMimeTypes = false

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
                provider.loadItem(forTypeIdentifier: String(UTType.image.identifier), options: nil) { (object, error) in
                    if let image = object as? UIImage {
                        self.processedMedia.append(SunlitMedia(withImage: image))
                        self.processNextProvider()
                    }
                    else {
                        provider.loadInPlaceFileRepresentation(forTypeIdentifier: String(UTType.image.identifier)) { (url, success, error) in
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

        var type = String(UTType.movie.identifier)
		if #available(iOS 14, *) {
			type = UTType.movie.identifier
		}
		//_ = provider.loadItem(forTypeIdentifier: String(kUTTypeMovie), options: nil, completionHandler: { url, error in
		//_ = provider.loadInPlaceFileRepresentation(forTypeIdentifier: type, completionHandler: { (url, success, error) in
		_ = provider.loadFileRepresentation(forTypeIdentifier: type, completionHandler: { url, error in
            if let videoURL = url {

				let fm = FileManager.default
				let name = UUID().uuidString
				let destination = fm.temporaryDirectory.appendingPathComponent(name + ".mov")
				do {
					try fm.copyItem(at: videoURL, to: destination)
				}
				catch {
					self.providerFailed(error)
					return
				}

				DispatchQueue.main.async {
					self.processedMedia.append(SunlitMedia(withVideo: destination))
					self.processNextProvider()
				}
            }
            else {
                self.providerFailed(error)
            }

        })

    }
}
