//
//  UUHttpSession.swift
//  Useful Utilities - URLSession wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

public typealias UUQueryStringArgs = [AnyHashable:Any]
public typealias UUHttpHeaders = [AnyHashable:Any]

public enum UUHttpMethod : String
{
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
}

public enum UUHttpSessionError : Int
{
    // Returned when URLSession returns a non-nil error and the underlying
    // error domain is NSURLErrorDomain and the underlying error code is
    // NSURLErrorNotConnectedToInternet
    case noInternet = 0x1000
    
    // Returned when URLSession returns a non-nil error and the underlying
    // error domain is NSURLErrorDomain and the underlying error code is
    // NSURLErrorCannotFindHost
    case cannotFindHost = 0x1001
    
    // Returned when URLSession returns a non-nil error and the underlying
    // error domain is NSURLErrorDomain and the underlying error code is
    // NSURLErrorTimedOut
    case timedOut = 0x1002
    
    // Returned when URLSession completion block returns a non-nil Error, and
    // that error is not specifically mapped to a more common UUHttpSessionError
    // In this case, the underlying NSError is wrapped in the user info block
    // using the NSUnderlyingError key
    case httpFailure = 0x2000
    
    // Returned when the URLSession completion block returns with a nil Error
    // and an HTTP return code that is not 2xx
    case httpError = 0x2001
    
    // Returned when a user cancels an operation
    case userCancelled = 0x2002
    
    // The request URL and/or query string parameters resulted in an invalid
    // URL.
    case invalidRequest = 0x2003
}

public let UUHttpSessionErrorDomain           = "UUHttpSessionErrorDomain"
public let UUHttpSessionHttpErrorCodeKey      = "UUHttpSessionHttpErrorCodeKey"
public let UUHttpSessionHttpErrorMessageKey   = "UUHttpSessionHttpErrorMessageKey"
public let UUHttpSessionAppResponseKey        = "UUHttpSessionAppResponseKey"

public struct UUContentType
{
    public static let applicationJson  = "application/json"
    public static let textJson         = "text/json"
    public static let textHtml         = "text/html"
    public static let textPlain        = "text/plain"
    public static let binary           = "application/octet-stream"
    public static let imagePng         = "image/png"
	public static let imageJpeg        = "image/jpeg"
	public static let formEncoded      = "application/x-www-form-urlencoded"
}

public struct UUHeader
{
    public static let contentLength = "Content-Length"
    public static let contentType = "Content-Type"
}

public class UUHttpRequest: NSObject
{
	public static var defaultTimeout : TimeInterval = 60.0
	public static var defaultCachePolicy : URLRequest.CachePolicy = .useProtocolCachePolicy
	
    public var url : String = ""
    public var httpMethod : UUHttpMethod = .get
    public var queryArguments : UUQueryStringArgs = [:]
    public var headerFields : UUHttpHeaders = [:]
    public var body : Data? = nil
    public var bodyContentType : String? = nil
	public var timeout : TimeInterval = UUHttpRequest.defaultTimeout
	public var cachePolicy : URLRequest.CachePolicy = UUHttpRequest.defaultCachePolicy
    public var credentials : URLCredential? = nil
    public var processMimeTypes : Bool = true
    public var startTime : TimeInterval = 0
    public var httpRequest : URLRequest? = nil
	public var httpTask : URLSessionTask? = nil
    public var responseHandler : UUHttpResponseHandler? = nil
    public var form : UUHttpForm? = nil
    
    public init(url : String, method: UUHttpMethod = .get, queryArguments: UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], body : Data? = nil, contentType : String? = nil)
    {
        super.init()
        
        self.url = url
        self.httpMethod = method
        self.queryArguments = queryArguments
        self.headerFields = headers
        self.body = body
        self.bodyContentType = contentType
    }
    
    public convenience init(url : String, method: UUHttpMethod = .post, queryArguments: UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], form : UUHttpForm)
    {
        self.init(url: url, method: method, queryArguments: queryArguments, headers: headers, body: nil, contentType: nil)
        self.form = form
    }
	
	public func cancel() {
		self.httpTask?.cancel()
	}
}

public class UUHttpResponse : NSObject
{
    public var httpError : Error? = nil
    public var httpRequest : UUHttpRequest? = nil
    public var httpResponse : HTTPURLResponse? = nil
    public var parsedResponse : Any?
    public var rawResponse : Data? = nil
    public var rawResponsePath : String = ""
    public var downloadTime : TimeInterval = 0
    
    init(_ request : UUHttpRequest, _ response : HTTPURLResponse?)
    {
        httpRequest = request
        httpResponse = response
    }
}

public class UUHttpForm : NSObject
{
    public var formBoundary: String = "UUForm_PostBoundary"
    private var formBuilder: NSMutableData = NSMutableData()
    
    public func add(field: String, value: String, contentType: String = UUContentType.textPlain, encoding: String.Encoding = .utf8)
    {
        appendNewLineIfNeeded()
        
        if let boundaryBytes = boundaryBytes(),
           let fieldNameBytes = "Content-Disposition: form-data; name=\"\(field)\"\r\n\r\n".data(using: .utf8),
           let contentTypeBytes = contentTypeBytes(contentType),
           let fieldValueBytes = value.data(using: encoding)
        {
            formBuilder.append(boundaryBytes)
            formBuilder.append(fieldNameBytes)
            formBuilder.append(contentTypeBytes)
            formBuilder.append(fieldValueBytes)
        }
    }
    
    public func addFile(fieldName: String, fileName: String, contentType: String, fileData: Data)
    {
        appendNewLineIfNeeded()
        
        if let boundaryBytes = boundaryBytes(),
            let fieldNameBytes = "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8),
            let contentTypeBytes = contentTypeBytes(contentType)
        {
            formBuilder.append(boundaryBytes)
            formBuilder.append(fieldNameBytes)
            formBuilder.append(contentTypeBytes)
            formBuilder.append(fileData)
        }
    }
    
    private func boundaryBytes() -> Data?
    {
        return "--\(formBoundary)\r\n".data(using: .utf8)
    }
    
    private func endBoundaryBytes() -> Data?
    {
        return "\r\n--\(formBoundary)--\r\n".data(using: .utf8)
    }
    
    private func contentTypeBytes(_ contentType: String) -> Data?
    {
        return "Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)
    }
    
    private func appendNewLineIfNeeded()
    {
        if (formBuilder.length > 0)
        {
            if let bytes = "\r\n".data(using: .utf8)
            {
                formBuilder.append(bytes)
            }
        }
    }
    
    public func formData() -> Data?
    {
        guard let tmp = formBuilder.mutableCopy() as? NSMutableData, let endBoundaryBytes = endBoundaryBytes() else
        {
            return nil
        }
        
        tmp.append(endBoundaryBytes)
        return tmp as Data
    }
    
    public func formContentType() -> String
    {
        return "multipart/form-data; boundary=\(formBoundary)"
    }
}

public protocol UUHttpResponseHandler
{
    var supportedMimeTypes : [String] { get }
    func parseResponse(_ data : Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
}

open class UUTextResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.textHtml, UUContentType.textPlain]
    }
    
    open func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        var parsed : Any? = nil
        
        var responseEncoding : String.Encoding = .utf8
        
        if (response.textEncodingName != nil)
        {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(response.textEncodingName as CFString?)
            responseEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        }
        
        let stringResult : String? = String.init(data: data, encoding: responseEncoding)
        if (stringResult != nil)
        {
            parsed = stringResult
        }
        
        return parsed
    }
}

open class UUBinaryResponseHandler : NSObject, UUHttpResponseHandler
{
    open var supportedMimeTypes: [String]
    {
        return [UUContentType.binary]
    }
    
    open func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        return data
    }
}

open class UUJsonResponseHandler : NSObject, UUHttpResponseHandler
{
    open var supportedMimeTypes: [String]
    {
        return [UUContentType.applicationJson, UUContentType.textJson]
    }
    
    open func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        do
        {
            return try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch (let err)
        {
            UUDebugLog("Error deserializing JSON: %@", String(describing: err))
        }
        
        return nil
    }
}

open class UUImageResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.imagePng, UUContentType.imageJpeg]
    }
    
    open func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
		#if os(macOS)
			return NSImage.init(data: data)
		#else
			return UIImage.init(data: data)
		#endif
    }
}

open class UUFormEncodedResponseHandler : NSObject, UUHttpResponseHandler
{
	public var supportedMimeTypes: [String]
	{
		return [UUContentType.formEncoded]
	}
	
	open func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
	{
		var parsed: [ String: Any ] = [:]
		
		if let s = String.init(data: data, encoding: .utf8) {
			let components = s.components(separatedBy: "&")
			for c in components {
				let pair = c.components(separatedBy: "=")
				if pair.count == 2 {
					if let key = pair.first {
						if let val = pair.last {
							parsed[key] = val.removingPercentEncoding
						}
					}
				}
			}
		}
		
		return parsed
	}
}

@objc
public class UUHttpSession: NSObject
{
    private var urlSession : URLSession? = nil
    private var sessionConfiguration : URLSessionConfiguration? = nil
    private var activeTasks : UUThreadSafeArray<URLSessionTask> = UUThreadSafeArray()
    private var responseHandlers : [String:UUHttpResponseHandler] = [:]
    
    public static let shared = UUHttpSession()
    
    required override public init()
    {
        super.init()
        
        sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration?.timeoutIntervalForRequest = UUHttpRequest.defaultTimeout
        
        urlSession = URLSession.init(configuration: sessionConfiguration!)
        
        installDefaultResponseHandlers()
    }
    
    private func installDefaultResponseHandlers()
    {
        registerResponseHandler(UUJsonResponseHandler())
        registerResponseHandler(UUTextResponseHandler())
        registerResponseHandler(UUBinaryResponseHandler())
		registerResponseHandler(UUImageResponseHandler())
		registerResponseHandler(UUFormEncodedResponseHandler())
    }
    
    private func registerResponseHandler(_ handler : UUHttpResponseHandler)
    {
        for mimeType in handler.supportedMimeTypes
        {
            responseHandlers[mimeType] = handler
        }
    }
    
    private func executeRequest(_ request : UUHttpRequest, _ completion: @escaping (UUHttpResponse) -> Void) -> UUHttpRequest
    {
        let httpRequest : URLRequest? = buildRequest(request)
        if (httpRequest == nil)
        {
            let uuResponse : UUHttpResponse = UUHttpResponse(request, nil)
            uuResponse.httpError = NSError.init(domain: UUHttpSessionErrorDomain, code: UUHttpSessionError.invalidRequest.rawValue, userInfo: nil)
            completion(uuResponse)
            return request
        }
        
        request.httpRequest = httpRequest!
        
        request.startTime = Date.timeIntervalSinceReferenceDate
        
        /*UUDebugLog("Begin Request\n\nMethod: %@\nURL: %@\nHeaders: %@)",
            String(describing: request.httpRequest?.httpMethod),
            String(describing: request.httpRequest?.url),
            String(describing: request.httpRequest?.allHTTPHeaderFields))
        
        if (request.body != nil)
        {
            if (UUContentType.applicationJson == request.bodyContentType)
            {
                UUDebugLog("JSON Body: %@", request.body!.uuToJsonString())
            }
            else
            {
                if (request.body!.count < 10000)
                {
                    UUDebugLog("Raw Body: %@", request.body!.uuToHexString())
                }
            }
        }
        */
        let task = urlSession!.dataTask(with: request.httpRequest!)
        { (data : Data?, response: URLResponse?, error : Error?) in
			
			if let httpTask = request.httpTask {
				self.activeTasks.remove(httpTask)
			}
            self.handleResponse(request, data, response, error, completion)
        }
		request.httpTask = task
		
        activeTasks.append(task)
        task.resume()
        return request
    }
    
    private func buildRequest(_ request : UUHttpRequest) -> URLRequest?
    {
        var fullUrl = request.url;
        if (request.queryArguments.count > 0)
        {
            fullUrl = "\(request.url)\(request.queryArguments.uuBuildQueryString())"
        }
        
        guard let url = URL.init(string: fullUrl) else
        {
            return nil
        }
        
        var req : URLRequest = URLRequest(url: url)
        req.httpMethod = request.httpMethod.rawValue
        req.timeoutInterval = request.timeout
		req.cachePolicy = request.cachePolicy
        
        for key in request.headerFields.keys
        {
            let strKey = (key as? String) ?? String(describing: key)
            
            if let val = request.headerFields[key]
            {
                let strVal = (val as? String) ?? String(describing: val)
                req.addValue(strVal, forHTTPHeaderField: strKey)
            }
        }
        
        if let form = request.form
        {
            request.body = form.formData()
            request.bodyContentType = form.formContentType()
        }
        
        if (request.body != nil)
        {
            req.setValue(String.init(format: "%lu", request.body!.count), forHTTPHeaderField: UUHeader.contentLength)
            req.httpBody = request.body
            
            if (request.bodyContentType != nil && request.bodyContentType!.count > 0)
            {
                req.addValue(request.bodyContentType!, forHTTPHeaderField: UUHeader.contentType)
            }
        }
        
        return req
    }
    
    private func handleResponse(
        _ request : UUHttpRequest,
        _ data : Data?,
        _ response : URLResponse?,
        _ error : Error?,
        _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let httpResponse : HTTPURLResponse? = response as? HTTPURLResponse
        
        let uuResponse : UUHttpResponse = UUHttpResponse(request, httpResponse)
        uuResponse.rawResponse = data
        
        var err : Error? = error
        var parsedResponse : Any? = nil
        
        var httpResponseCode : Int = 0
        
        if (httpResponse != nil)
        {
            httpResponseCode = httpResponse!.statusCode
        }
        
		/*
        UUDebugLog("Http Response Code: %d", httpResponseCode)
        
        if let responseHeaders = httpResponse?.allHeaderFields
        {
            UUDebugLog("Response Headers: %@", responseHeaders)
        }
		*/
        
        if (error != nil)
        {
            UUDebugLog("Got an error: %@", String(describing: error!))
        }
        else
        {
            if (request.processMimeTypes)
            {
                parsedResponse = parseResponse(request, httpResponse, data)
                if (parsedResponse is Error)
                {
                    err = (parsedResponse as! Error)
                    parsedResponse = nil
                }
            }
            
            // By default, the standard response parsers won't emit an Error, but custom response handlers might.
            // When callers parse response JSON and return Errors, we will honor that.
            if (err == nil && !isHttpSuccessResponseCode(httpResponseCode))
            {
                var d : [String:Any] = [:]
                d[UUHttpSessionHttpErrorCodeKey] = NSNumber(value: httpResponseCode)
                d[UUHttpSessionHttpErrorMessageKey] = HTTPURLResponse.localizedString(forStatusCode: httpResponseCode)
                d[UUHttpSessionAppResponseKey] = parsedResponse
                d[NSLocalizedDescriptionKey] = HTTPURLResponse.localizedString(forStatusCode: httpResponseCode)

                err = NSError.init(domain:UUHttpSessionErrorDomain, code:UUHttpSessionError.httpError.rawValue, userInfo:d)
            }
        }
        
        uuResponse.httpError = err;
        uuResponse.parsedResponse = parsedResponse;
        uuResponse.downloadTime = Date.timeIntervalSinceReferenceDate - request.startTime
        
        completion(uuResponse)
    }
    
    private func parseResponse(_ request : UUHttpRequest, _ httpResponse : HTTPURLResponse?, _ data : Data?) -> Any?
    {
        if (httpResponse != nil)
        {
            let httpRequest = request.httpRequest
            
            let mimeType = httpResponse!.mimeType
            
            /*UUDebugLog("Parsing response,\n%@ %@", String(describing: httpRequest?.httpMethod), String(describing: httpRequest?.url))
            UUDebugLog("Response Mime: %@", String(describing: mimeType))
            
            if let responseData = data
            {
                let logLimit = 10000
                var responseStr : String? = nil
                if (responseData.count > logLimit)
                {
                    responseStr = String(data: responseData.subdata(in: 0..<logLimit), encoding: .utf8)
                }
                else
                {
                    responseStr = String(data: responseData, encoding: .utf8)
                }
                
                //UUDebugLog("Raw Response: %@", String(describing: responseStr))
            }
            */
            var handler = request.responseHandler
            
            if (handler == nil && mimeType != nil)
            {
                handler = responseHandlers[mimeType!]
            }
            
            if (handler != nil && data != nil && httpRequest != nil)
            {
                let parsedResponse = handler!.parseResponse(data!, httpResponse!, httpRequest!)
                return parsedResponse
            }
        }
        
        return nil
    }
    
    private func isHttpSuccessResponseCode(_ responseCode : Int) -> Bool
    {
        return (responseCode >= 200 && responseCode < 300)
    }
    
    public static func executeRequest(_ request : UUHttpRequest, _ completion: @escaping (UUHttpResponse) -> Void) -> UUHttpRequest
    {
        return shared.executeRequest(request, completion)
    }
    
    public static func get(url : String, queryArguments : UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest(url: url, method: .get, queryArguments: queryArguments)
        _ = executeRequest(req, completion)
    }
    
    public static func delete(url : String, queryArguments : UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest(url: url, method: .delete, queryArguments: queryArguments)
        _ = executeRequest(req, completion)
    }
    
    public static func put(url : String, queryArguments : UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], body: Data?, contentType : String?, completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest(url: url, method: .put, queryArguments: queryArguments, body: body, contentType: contentType)
        _ = executeRequest(req, completion)
    }
    
    public static func post(url : String, queryArguments : UUQueryStringArgs = [:], headers: UUHttpHeaders = [:], body: Data?, contentType : String?, completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest(url: url, method: .post, queryArguments: queryArguments, body: body, contentType: contentType)
        _ = executeRequest(req, completion)
    }
    
    public static func registerResponseHandler(_ handler : UUHttpResponseHandler)
    {
        shared.registerResponseHandler(handler)
    }
}
