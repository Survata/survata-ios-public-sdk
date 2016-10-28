//
//  Survey.swift
//  Survata
//
//  Created by Rex Sheng on 2/11/16.
//  Copyright © 2016 Survata. All rights reserved.
//

import WebKit
import AdSupport

/**
enum status returned in create api
*/
@objc public enum SVSurveyAvailability: Int {
	case Available
	case NotAvailable
	case Error
}

/**
enum status returned in present api
*/
@objc public enum SVSurveyResult: Int {
	case Completed
	case Skipped
	case Canceled
	case CreditEarned
	case NoSurveyAvailable
	case NetworkNotAvailable
}

/**
when Survey.verbose is true, log text will be sent to this delegate
*/
@objc(SVSurveyDebugDelegate) public protocol SurveyDebugDelegate: NSObjectProtocol {
	func surveyLog(log: String)
}

/**
SurveyOption for Survata.
do not modify it after sending to Survey.create
*/
@objc(SVSurveyOption) public class SurveyOption: NSObject {
	public var brand: String?
	public var explainer: String?
	public let publisher: String
	public var contentName: String?
    public var preview: String?
    public var testing: Bool?

	public init(publisher: String) {
		self.publisher = publisher
	}

	var mobileAdId: String? {
		if ASIdentifierManager.sharedManager().advertisingTrackingEnabled {
			return ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
		}
		return nil
	}

	func optionForSDK(zipcode: String?) -> [String: AnyObject] {
		var option: [String: AnyObject] = [:]
		option["mobileAdId"] = mobileAdId
		option["publisherUuid"] = publisher
		option["contentName"] = contentName
		option["postalCode"] = zipcode
        option["preview"] = preview
        option["testing"] = testing
		return option
	}

	func optionForJS(zipcode: String?) -> [String: AnyObject] {
		var option: [String: AnyObject] = [:]
		option["brand"] = brand
		option["explainer"] = explainer
		option["contentName"] = contentName
		option["mobileAdId"] = mobileAdId
		option["postalCode"] = zipcode
        option["preview"] = preview
        option["testing"] = testing
		return option
	}
}

public protocol SurveyDebugOptionProtocol {
	var preview: String? { get }
	var zipcode: String? { get }
	var sendZipcode: Bool { get }
}

private func jsonString(object: [String: AnyObject]) -> String {
	let optionData = try! NSJSONSerialization.dataWithJSONObject(object, options: [])
	return String(data: optionData, encoding: NSUTF8StringEncoding) ?? "{}"
}

private var mediaWindow: UIWindow?
private func createMediaWindow() -> UIWindow! {
	if mediaWindow == nil {
		let window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window.windowLevel = UIWindowLevelNormal
		window.makeKeyAndVisible()
		window.hidden = false
		window.backgroundColor = UIColor.clearColor()
		mediaWindow = window
	}
	return mediaWindow
}

private func disposeMediaWindow() {
	UIView.animateWithDuration(0.3, animations: {
		mediaWindow?.alpha = 0
	}) { _ in
		UIApplication.sharedApplication().delegate?.window??.makeKeyAndVisible()
		mediaWindow?.hidden = true
		mediaWindow?.rootViewController = nil
		mediaWindow = nil
	}
}

//Survata Survey
@objc(SVSurvey) public class Survey: NSObject {
	private static let urlString = "https://surveywall-api.survata.com/rest/interview-check/create"
	// setting to ture will print every detail of this api. default to true
	public static var verbose: Bool = true
	private var availability: SVSurveyAvailability!
	// log will be sent to debugDelegate if verbose is set to true
	public weak var debugDelegate: SurveyDebugDelegate?
	let option: SurveyOption
	var zipcode: String?

	/**
	- parameter option: creation options
	*/
	public init(option: SurveyOption) {
		self.option = option
	}

	/**
	create: call this function to initialize Survata
	- parameter completion: closure to callback availability

	cause the availability can be changed from time to time, please use this method right before `createSurveyWall`. Results of presentation on availability other than `.Available` is not guaranteed.

	e.g. use the availability to determine wether to show the survata button and the button will trigger presentation
	*/
	public func create(completion: SVSurveyAvailability -> ()) {
		if !Survey.isConnectedToNetwork() {
			completion(.Error)
			return
		}
		if let option = option as? SurveyDebugOptionProtocol {
			if option.sendZipcode {
				if let zipcode = option.zipcode {
					self.zipcode = zipcode
					_create(completion)
				} else {
					Geocode.Current.get {[weak self] postalCode in
						self?.zipcode = postalCode
						self?._create(completion)
					}
				}
				return
			}
		}
		_create(completion)
	}

	func _create(completion: SVSurveyAvailability -> ()) {
		let json = option.optionForSDK(zipcode)
		let next = {[weak self] (availability: SVSurveyAvailability) -> () in
			self?.availability = availability
			completion(availability)
		}
		print("Survey.create sending \(json)...")
		Survey.post(Survey.urlString, json: json) {[weak self] (object, error) in
			if let object = object {
				self?.print("Survey.create response \(object)")
				if let valid = object["valid"] as? Bool where !valid {
					next(.NotAvailable)
					return
				}
				if let errorCode = object["errorCode"] where !(errorCode is NSNull) {
					next(.Error)
					return
				}
				next(.Available)
			} else {
				next(.Error)
			}
		}
	}

	/**
	createSurveyWall: to present survata over the `parent` view controller.
	- parameter completion: callbacks survey result

	- SeeAlso: `create`

	- Note: client code should hold this instance before completion
	*/
	public func createSurveyWall(completion: SVSurveyResult -> ()) {
		if availability == nil || !Survey.isConnectedToNetwork() {
			completion(.NetworkNotAvailable)
			return
		}

		let controller = SurveyViewController()
		controller.survey = self
		controller.onCompletion = { r in
			disposeMediaWindow()
			completion(r)
		}
		createMediaWindow().rootViewController = controller
	}

	func print(log: String) {
		if Survey.verbose {
			debugDelegate?.surveyLog(log)
			Swift.print("\(NSDate()) \(log)")
		}
	}
}

@IBDesignable
class SurveyView: UIView, WKScriptMessageHandler {
	static let events = ["load", "interviewComplete", "interviewSkip", "interviewStart", "noSurveyAvailable", "fail", "ready", "log"]
	weak var webView: WKWebView!
	weak var survey: Survey?
	weak var closeButton: UIControl!
	weak var topBar: UIView!

	var events: [String: [(AnyObject) -> ()]] = [:]

	override init(frame: CGRect) {
		super.init(frame: frame)
		_setup()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		_setup()
	}

	private func _setup() {
		backgroundColor = UIColor.whiteColor()
		let bar = UIView()
		bar.backgroundColor = UIColor(white: 0.96, alpha: 1)
		bar.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bar)
		bar.fullWidth()
		bar.fixAttribute(.Height, value: 64)
		bar.toTheTop()
		topBar = bar

		let closeButton = CloseButton()
		closeButton.opaque = false
		closeButton.translatesAutoresizingMaskIntoConstraints = false
		bar.addSubview(closeButton)
		closeButton.fixAttribute(.Width, value: 42)
		closeButton.fixAttribute(.Height, value: 42)
		closeButton.toTheRight()
		closeButton.toTheBottom()
		self.closeButton = closeButton
		bar.hidden = true

		let contentController = WKUserContentController()
		SurveyView.events.forEach { contentController.addScriptMessageHandler(self, name: $0) }
		let configuration = WKWebViewConfiguration()
		configuration.userContentController = contentController
		configuration.allowsInlineMediaPlayback = true
		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(webView)
		addConstraint(NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: bar, attribute: .Bottom, multiplier: 1, constant: 0))
		webView.toTheBottom()
		webView.fullWidth()
		webView.scrollView.showsVerticalScrollIndicator = false
		webView.scrollView.showsHorizontalScrollIndicator = false
		self.webView = webView
	}

	deinit {
		SurveyView.events.forEach { webView.configuration.userContentController.removeScriptMessageHandlerForName($0) }
	}

	func createSurveyWall(survey: Survey) {
		self.survey = survey
		let bundle = NSBundle(forClass: classForCoder)
		if let templateFile = bundle.URLForResource("template", withExtension: "html"),
			let template = try? String(contentsOfURL: templateFile, encoding: NSUTF8StringEncoding) {
			let loader = NSData(contentsOfURL: bundle.URLForResource("survata-spinner", withExtension: "png")!)!.base64EncodedStringWithOptions([])
			let json = survey.option.optionForJS(survey.zipcode)
			let optionString = jsonString(json)
			let html = template
				.stringByReplacingOccurrencesOfString("[PUBLISHER_ID]", withString: survey.option.publisher)
				.stringByReplacingOccurrencesOfString("[OPTION]", withString: optionString)
				.stringByReplacingOccurrencesOfString("[LOADER_BASE64]", withString: loader)
			survey.print("loading survata option = \(optionString)...")
			webView.loadHTMLString(html, baseURL: NSURL(string: "https://www.survata.com"))
		}
	}

	func on(event: String, closure: (AnyObject) -> ()) {
		if var _events = events[event] {
			_events.append(closure)
		} else {
			events[event] = [closure]
		}
	}

	func startInterview() {
		webView.evaluateJavaScript("var _ = startInterview();", completionHandler: nil)
	}

	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		survey?.print("Survata.js on event '\(message.name)'")
		events[message.name]?.forEach { $0(message.body) }
	}
}

class SurveyViewController: UIViewController {
	weak var surveyView: SurveyView!
	weak var survey: Survey!

	var margin: CGFloat = 0
	var onCompletion: ((SVSurveyResult) -> ())?

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return .All
	}

	var timer: dispatch_source_t!

	override func viewDidLoad() {
		view.backgroundColor = UIColor.clearColor()
		let blur = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
		view.addSubview(blur)
		blur.frame = view.bounds
		blur.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

		let surveyView = SurveyView(frame: .zero)
		surveyView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(surveyView)
		fullWidth(surveyView, margin: margin)
		fullHeight(surveyView, margin: margin)
		surveyView.layer.borderColor = UIColor(white: 0.2, alpha: 1).CGColor
		surveyView.layer.borderWidth = 1
		self.surveyView = surveyView

		surveyView.closeButton.addTarget(self, action: #selector(close), forControlEvents: .TouchUpInside)
		surveyView.on("ready") {[weak self] _ in
			self?.surveyView?.startInterview()
		}

		surveyView.on("load") {[weak self] data in
			self?.survey.print("data \(data)")
			let testing = self?.survey?.option.testing ?? false
			let previewOption = (self?.survey?.option.preview ?? "")
			let notAPreview = previewOption.isEmpty
			if let data = data as? [String: AnyObject] {
				if data["status"] as? String == "monetizable" {
					surveyView.topBar?.hidden = false
					//continue
				} else {
					self?.dismissViewControllerAnimated(true, completion: nil)
					self?.onCompletion?(.CreditEarned)
				}
			} else if !testing && notAPreview {
				self?.dismissViewControllerAnimated(true, completion: nil)
				self?.onCompletion?(.NoSurveyAvailable)
			}
		}
		surveyView.on("interviewComplete") {[weak self] _ in
			self?.dismissViewControllerAnimated(true, completion: nil)
			self?.onCompletion?(.Completed)
		}

		//never seen this happening
		surveyView.on("interviewSkip") {[weak self] _ in
			self?.dismissViewControllerAnimated(true, completion: nil)
			self?.onCompletion?(.Skipped)
		}

		surveyView.on("noSurveyAvailable") {[weak self] _ in
			self?.dismissViewControllerAnimated(true, completion: nil)
			self?.onCompletion?(.NoSurveyAvailable)
		}

		surveyView.createSurveyWall(survey)
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
		dispatch_resume(timer)
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(2 * Double(NSEC_PER_SEC)), 0)
		dispatch_source_set_event_handler(timer) {[weak self] in
			if !Survey.isConnectedToNetwork() {
				self?.dismissViewControllerAnimated(true, completion: nil)
				self?.onCompletion?(.NetworkNotAvailable)
			}
		}
	}

	override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
		dispatch_source_cancel(timer)
		view.removeFromSuperview()
		removeFromParentViewController()
	}

	deinit {
		if timer != nil {
			dispatch_source_cancel(timer)
		}
	}

	func close() {
		dismissViewControllerAnimated(true, completion: nil)
		onCompletion?(.Canceled)
	}
}