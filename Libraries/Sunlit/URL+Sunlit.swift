//
//  URL+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/27/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

extension URL {
	
	static func createTempFile() -> URL {
		let documentsURL = self.documentsDirectory()
		let filename = self.generateUniqueFilename(myFileName: "SunlitTempFile-")
		
		let completeURL = URL(fileURLWithPath: filename, relativeTo: documentsURL)
		return completeURL
	}
	
	static func generateUniqueFilename (myFileName: String) -> String {
		let guid = ProcessInfo.processInfo.globallyUniqueString
		let uniqueFileName = ("\(myFileName)_\(guid)")
		return uniqueFileName
	}
	
	static func documentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
}
