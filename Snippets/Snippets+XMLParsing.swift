//
//  Snippets+XMLParsing.swift
//  Snippets
//
//  Created by Jonathan Hays on 12/17/18.
//  Copyright © 2018 Micro.blog. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import UUSwift



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - SnippetsXMLLinkParser
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


public class SnippetsXMLLinkParser: NSObject {

	@objc public static func parse(_ data : Data, relValue : String = "") -> [String] {
		
		var foundURLs : [String] = []
		
		if var string : NSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
			var startingPosition : NSRange = string.range(of: "<link", options: .caseInsensitive)
			while startingPosition.location != NSNotFound {
				let rel = self.extractTagValue("rel", sourceString: string)
				if (relValue.count == 0 || rel == relValue) {
					if let href = self.extractTagValue("href", sourceString: string) {
						foundURLs.append(href)
					}
				}
				
				string = string.substring(from: startingPosition.location + startingPosition.length) as NSString
				startingPosition = string.range(of: "<link", options: .caseInsensitive)
			}

			// Grab the last one found, which occurs outside of the loop...
			if string.length > 0 {
				let rel = self.extractTagValue("rel", sourceString: string)
				if (relValue.count == 0 || rel == relValue) {
					if let href = self.extractTagValue("href", sourceString: string) {
						foundURLs.append(href)
					}
				}
			}
			
		}
		
		return foundURLs
	}
	
	static private func extractTagValue(_ tagName : String, sourceString : NSString) -> String?
	{
		let string = sourceString as NSString
		let startingPosition : NSRange = string.range(of: tagName, options: .caseInsensitive)
		if startingPosition.location != NSNotFound {
			let substring = string.substring(from: startingPosition.location) as NSString
			var stringStartPosition = substring.range(of: "\"", options: .caseInsensitive)
			let singleQuoteStartPosition = substring.range(of: "'", options: .caseInsensitive)
			
			var isSingleQuote = false
			
			if (stringStartPosition.location == NSNotFound && singleQuoteStartPosition.location != NSNotFound)
			{
				isSingleQuote = true
				stringStartPosition = singleQuoteStartPosition
			}
			else if (singleQuoteStartPosition.location != NSNotFound &&
					 singleQuoteStartPosition.location < stringStartPosition.location)
			{
				isSingleQuote = true
				stringStartPosition = singleQuoteStartPosition
			}
			
			if stringStartPosition.location != NSNotFound {
				let valueString = substring.substring(from: stringStartPosition.location + 1) as NSString
				var endPosition = valueString.range(of: "\"", options: .caseInsensitive)
				if isSingleQuote {
					endPosition = valueString.range(of: "'", options: .caseInsensitive)
				}
				
				let parsedString = valueString.substring(to: endPosition.location)
				return parsedString
			}
		}
		
		return nil
	}

}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - SnippetsXMLRPCParser
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class SnippetsXMLRPCParser: NSObject, XMLParserDelegate {

	@objc static public func parsedResponseFromData(_ data : Data, completion:@escaping([String : Any]?, [Any]) ->()) {
		let parser = XMLParser(data: data)
		let xmlrpc = SnippetsXMLRPCParser()
		parser.delegate = xmlrpc
		
		parser.parse()
	
		completion(xmlrpc.responseFault, xmlrpc.responseParams)
	}


	var responseParams : [Any] = []
	var responseFault : [String : Any]? = nil

	var responseStack : MBXMLElementStack = MBXMLElementStack()
	var currentMemberName : NSMutableString? = nil
	var finishedMemberName = ""
	var currentValue : Any? = nil
	var processingString = false


	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		
		if elementName == "params" {
		}
		else if elementName == "param" {
		}
		else if elementName == "value" {
		}
		else if elementName == "array" {
			self.currentValue = NSMutableArray()
			self.responseStack.push(self.currentValue!)
		}
		else if elementName == "struct" {
			self.currentValue = NSMutableDictionary()
			self.responseStack.push(self.currentValue!)
		}
		else if elementName == "name" {
			self.currentMemberName = NSMutableString()
		}
		else if elementName == "string" {
			self.currentValue = NSMutableString()
			self.processingString = true
		}
		else if elementName == "int" {
			self.currentValue = NSMutableString()
			self.processingString = true
		}
		else if elementName == "i4" {
			self.currentValue = NSMutableString()
			self.processingString = true
		}
		else if elementName == "boolean" {
			self.currentValue = NSMutableString()
			self.processingString = true
		}
	}

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		if let memberName = self.currentMemberName {
			memberName.append(string)
			self.currentMemberName = memberName
		}
		else if self.processingString {
			let stringValue = self.currentValue as! NSMutableString
			stringValue.append(string)
			self.currentValue = stringValue
		}
	}

	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

		if elementName == "param" {
			self.responseParams.append(self.currentValue!)
		}
		else if elementName == "fault" {
			self.responseFault = self.currentValue as? [String : Any]
		}
		else if elementName == "array" {
			self.currentValue = self.responseStack.pop()!
		}
		else if elementName == "struct" {
			self.currentValue = self.responseStack.pop()!
		}
		else if elementName == "value" {
			if let current_array = self.responseStack.peek() as? NSMutableArray {
				current_array.add(self.currentValue!)
			}
		}
		else if elementName == "member" {
			if let current_struct = self.responseStack.peek() as? NSMutableDictionary {
				current_struct[self.finishedMemberName] = self.currentValue
			}
		}
		else if elementName == "name" {
			if let memberName = self.currentMemberName {
				self.finishedMemberName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
				self.currentMemberName = nil
			}
		}
		else if elementName == "int" {
			let string = self.currentValue as! NSMutableString
			let result = string.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
			self.currentValue = NSNumber(value: result.integerValue)
			self.processingString = false
		}
		else if elementName == "boolean" {
			let string = self.currentValue as! NSMutableString
			let result = string.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
			self.currentValue = NSNumber(value: result.integerValue)
			self.processingString = false
		}
		else if elementName == "string" {
			let string = self.currentValue as! NSMutableString
			let result = string.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
			self.currentValue = result
			self.processingString = false
		}

	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - SnippetsRPCDiscovery
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class SnippetsRPCDiscovery: NSObject {

	var url : String = ""

	@objc public convenience init(url : String)
	{
		self.init()
		self.url = url
	}

	@objc public func discoverEndpointWithCompletion(handler : @escaping(String?, String?) -> ()) {
		self.getPath("") { (response : UUHttpResponse) in
			if let data = response.rawResponse
			{
				let rsd = MBXMLRSDParser.parsedResponseFromData(data)
				if (rsd.foundEndpoints.count > 0)
				{
					self.processRSD(dictionaryEndpoints: rsd.foundEndpoints, completion: handler)
					return
				}
			}
			
			handler(nil, nil)
		}
	}


	func getPath(_ path : String, completion: @escaping(UUHttpResponse) -> ()) {
		var full_url : NSString = self.url as NSString
		full_url = full_url.appendingPathComponent(path) as NSString
		let request = UUHttpRequest(url:full_url as String, method: .get)
		_ = UUHttpSession.executeRequest(request, completion)
	}
	
	func escapeParam(_ value : String) -> String
	{
		var s = value
		s = s.replacingOccurrences(of: "&", with: "&amp;")
		s = s.replacingOccurrences(of: "\"", with: "&quot;")
		s = s.replacingOccurrences(of: "'", with: "&#x27;")
		s = s.replacingOccurrences(of: ">", with: "&gt;")
		s = s.replacingOccurrences(of: "<", with: "&lt;")

		return s
	}
	
	func paramString(param : Any) -> String
	{
		var requestString = ""
		
		if let boolParam = param as? MBBoolean {
			requestString += "<value><boolean>\(boolParam.boolValue)</boolean></value>"
		}
		else if let numberParam = param as? NSNumber {
			requestString += "<value><int>\(numberParam.intValue)</int></value>"
		}
		else if let stringParam = param as? String {
			let escapedParam = self.escapeParam(stringParam)
			requestString += "<value><string>\(escapedParam)</string></value>"
		}
		else if let dictionary = param as? NSDictionary {
			requestString += "<value><struct>"
			let keys = dictionary.allKeys
			for k in keys {
				if let val = dictionary.object(forKey: k) {
					requestString += "<member><name>\(k)</name>"
					requestString += self.paramString(param: val)
					requestString += "</member>"
				}
			}
			requestString += "</struct></value>"
		}
		else if let array = param as? NSArray {
			requestString += "<value><array><data>"
			for val : Any in array {
				requestString += paramString(param: val)
			}
			requestString += "</data></array></value>"
		}
		else if let d = param as? NSData {
			requestString += "<value><base64>\(d.base64EncodedString(options: .init(rawValue: 0)))</base64></value>"
		}
		
		return requestString
	}
	
	
	func sendMethod(method : String, params : [Any], completion : @escaping(UUHttpResponse) -> ()) -> UUHttpRequest {
		var s = "<?xml version =\"1.0\"?>"
		s += "<methodCall><methodName>\(method)</methodName><params>"
		
		for param in params {
			s += "<param>"
			s += paramString(param: param)
			s += "</param>"
		}
		
		s += "</params>"
		s += "</methodCall>"
		
		let d = s.data(using: .utf8)
		let request = UUHttpRequest(url:self.url, method: .post, body: d, contentType: "text/xml")
		request.processMimeTypes = false
		
		return UUHttpSession.executeRequest(request, completion)
	}
	
	func processRSD(dictionaryEndpoints : [[String : String]], completion:@escaping(String?, String?) -> ()) {
		var best_endpoint_url : String? = nil
		var blog_id : String? = nil
		
		for api : Dictionary in dictionaryEndpoints {
			if api["name"] == "Blogger" {
				blog_id = api["blogID"]
				best_endpoint_url = api["apiLink"]
				break
			}
		}
		
		completion(best_endpoint_url, blog_id)
	}

}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - MBXMLRSDParser
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class MBXMLRSDParser: NSObject, XMLParserDelegate {

	var foundEndpoints : [[String : String]] = []

	static func parsedResponseFromData(_ data : Data) -> MBXMLRSDParser {
		let parser = XMLParser(data: data)
		let rsd = MBXMLRSDParser()
		parser.delegate = rsd
		
		parser.parse()
		return rsd
	}
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		if elementName == "api" {
			self.foundEndpoints.append(attributeDict)
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - MBXMLElementStack
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class MBXMLElementStack: NSObject {

	var stackArray : [Any] = []

	func push(_ object : Any) {
		stackArray.append(object)
	}

	func pop() -> Any? {
		let result = self.stackArray.removeLast()
		return result
	}
	
	func peek() -> Any? {
		let result = self.stackArray.last
		return result
	}

}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - MBBoolean
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class MBBoolean : NSObject {

	var boolValue = false
	
	convenience init(_ bool:Bool)
	{
		self.init()
		self.boolValue = bool
	}
	
	func description() -> String
	{
		return "\(self.boolValue)"
	}
}
