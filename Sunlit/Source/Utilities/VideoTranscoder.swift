//
//  VideoTranscoder.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/27/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import NextLevelSessionExporter

class VideoTranscoder {
	
	static func exportVideo(sourceUrl:URL, completion: @escaping ((Error?, URL) -> Void)) {

        let asset = AVURLAsset(url: sourceUrl, options: nil)
		let size = VideoTranscoder.calculateSizeForAsset(asset)
				
		let compressionDict: [String: Any] = [
			AVVideoAverageBitRateKey: NSNumber(integerLiteral: 3000000),
			AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel as String,
		]
		let videoOutputConfig : [String : Any] = [
			AVVideoCodecKey: AVVideoCodecType.h264,
			AVVideoWidthKey: NSNumber(integerLiteral: Int(size.width)),
			AVVideoHeightKey: NSNumber(integerLiteral: Int(size.height)),
			AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
			AVVideoCompressionPropertiesKey: compressionDict
		]
		let audioOutputConfig : [String : Any] = [
			AVFormatIDKey: kAudioFormatMPEG4AAC,
			AVEncoderBitRateKey: NSNumber(integerLiteral: 128000),
			AVNumberOfChannelsKey: NSNumber(integerLiteral: 2),
			AVSampleRateKey: NSNumber(value: Float(44100))
		]
		
		let exporter = NextLevelSessionExporter(withAsset: asset)
		exporter.audioOutputConfiguration = audioOutputConfig
		exporter.videoOutputConfiguration = videoOutputConfig
		
		let destination = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent(ProcessInfo().globallyUniqueString)
			.appendingPathExtension("mp4")
		
		exporter.outputURL = destination
		
		exporter.export(renderHandler: nil, progressHandler: nil) { (result) in
			switch result {
			case .success(let status):
				switch status {
				case .completed:
					// Placeholder...
					DispatchQueue.main.async {
						completion(nil, destination)
					}
					break
				default:
					print("NextLevelSessionExporter, did not complete")
					break
				}
				break
			case .failure(let error):
				DispatchQueue.main.async {
					completion(error, destination)
				}
				break
			}
		}
	}
	
	static func calculateSizeForAsset(_ asset : AVAsset) -> CGSize {
		
		let videoTracks = asset.tracks(withMediaType: .video)
		var size = CGSize(width: 640.0, height: 480.0)
		
		if let videoTrack = videoTracks.first {
			size = videoTrack.naturalSize.applying(videoTrack.preferredTransform);
			size.width = abs(size.width);
			size.height = abs(size.height);
		}
		
		if (size.width == 0) || (size.height == 0) {
			size.width = 640;
			size.height = 480;
		}
		else if ((size.width > 640) && (size.height > 640)) {
			if (size.width > size.height) {
				size.height = size.height * (640.0 / size.width)
				size.width = 640.0
			}
			else {
				size.width = size.width * (640.0 / size.height)
				size.height = 640.0
			}
		}
		
		return size
	}
}
