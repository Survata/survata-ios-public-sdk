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
	case available
	case notAvailable
	case error
}

/**
enum status returned in present api
*/
@objc public enum SVSurveyResult: Int {
	case completed
	case skipped
	case canceled
	case creditEarned
	case noSurveyAvailable
	case networkNotAvailable
}

/**
when Survey.verbose is true, log text will be sent to this delegate
*/
@objc(SVSurveyDebugDelegate) public protocol SurveyDebugDelegate: NSObjectProtocol {
	func surveyLog(_ log: String)
}

/**
SurveyOption for Survata.
do not modify it after sending to Survey.create
*/
@objc(SVSurveyOption) open class SurveyOption: NSObject {
	open var brand: String?
	open var explainer: String?
	open let publisher: String
	open var contentName: String?
    open var preview: String?
    open var testing: Bool?

	public init(publisher: String) {
		self.publisher = publisher
	}

	var mobileAdId: String? {
		if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
			return ASIdentifierManager.shared().advertisingIdentifier.uuidString
		}
		return nil
	}

	func optionForSDK(_ zipcode: String?) -> [String: AnyObject] {
		var option: [String: AnyObject] = [:]
		option["mobileAdId"] = mobileAdId as AnyObject?
		option["publisherUuid"] = publisher as AnyObject?
		option["contentName"] = contentName as AnyObject?
		option["postalCode"] = zipcode as AnyObject?
        option["preview"] = preview as AnyObject?
        option["testing"] = testing as AnyObject?
		return option
	}

	func optionForJS(_ zipcode: String?) -> [String: AnyObject] {
		var option: [String: AnyObject] = [:]
		option["brand"] = brand as AnyObject?
		option["explainer"] = explainer as AnyObject?
		option["contentName"] = contentName as AnyObject?
		option["mobileAdId"] = mobileAdId as AnyObject?
		option["postalCode"] = zipcode as AnyObject?
        option["preview"] = preview as AnyObject?
        option["testing"] = testing as AnyObject?
		return option
	}
}

public protocol SurveyDebugOptionProtocol {
	var preview: String? { get }
	var zipcode: String? { get }
	var sendZipcode: Bool { get }
}

private func jsonString(_ object: [String: AnyObject]) -> String {
	let optionData = try! JSONSerialization.data(withJSONObject: object, options: [])
	return String(data: optionData, encoding: String.Encoding.utf8) ?? "{}"
}

private var mediaWindow: UIWindow?
private func createMediaWindow() -> UIWindow! {
	if mediaWindow == nil {
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.windowLevel = UIWindowLevelNormal
		window.makeKeyAndVisible()
		window.isHidden = false
		window.backgroundColor = UIColor.clear
		mediaWindow = window
	}
	return mediaWindow
}

private func disposeMediaWindow() {
	UIView.animate(withDuration: 0.3, animations: {
		mediaWindow?.alpha = 0
	}, completion: { _ in
		UIApplication.shared.delegate?.window??.makeKeyAndVisible()
		mediaWindow?.isHidden = true
		mediaWindow?.rootViewController = nil
		mediaWindow = nil
	}) 
}

//Survata Survey
@objc(SVSurvey) open class Survey: NSObject {
//	fileprivate static let urlString = "https://surveywall-api.survata.com/rest/interview-check/create"
	fileprivate static let urlString = "http://192.168.0.87:8070/survata-surveywall/rest/interview-check/create";
	// setting `verbose` to true will print every detail of this api. default to true
	open static var verbose: Bool = true
	fileprivate var availability: SVSurveyAvailability!
	// log will be sent to debugDelegate if verbose is set to true
	open weak var debugDelegate: SurveyDebugDelegate?
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

	cause the availability can be changed from time to time, please use this method right before `createSurveyWall`. Results of presentation on availability other than `.available` is not guaranteed.

	e.g. use the availability to determine wether to show the survata button and the button will trigger presentation
	*/
	open func create(_ completion: @escaping (SVSurveyAvailability) -> ()) {
		if !Survey.isConnectedToNetwork() {
			completion(.error)
			return
		}
		if let option = option as? SurveyDebugOptionProtocol {
			if option.sendZipcode {
				if let zipcode = option.zipcode {
					self.zipcode = zipcode
					_create(completion)
				} else {
					Geocode.current.get {[weak self] postalCode in
						self?.zipcode = postalCode
						self?._create(completion)
					}
				}
				return
			}
		}
		_create(completion)
	}

	func _create(_ completion: @escaping (SVSurveyAvailability) -> ()) {
		let json = option.optionForSDK(zipcode)
		let next = {[weak self] (availability: SVSurveyAvailability) -> () in
			self?.availability = availability
			completion(availability)
		}
		print("Survey.create sending \(json)...")
		Survey.post(urlString: Survey.urlString, json: json) {[weak self] (object, error) in
			if let object = object {
				self?.print("Survey.create response \(object)")
				if let valid = object["valid"] as? Bool, !valid {
					next(.notAvailable)
					return
				}
				if let errorCode = object["errorCode"], !(errorCode is NSNull) {
					next(.error)
					return
				}
				next(.available)
			} else {
				next(.error)
			}
		}
	}

	/**
	createSurveyWall: to present survata over the `parent` view controller.
	- parameter completion: callbacks survey result

	- SeeAlso: `create`

	- Note: client code should hold this instance before completion
	*/
	open func createSurveyWall(_ completion: @escaping (SVSurveyResult) -> ()) {
		if availability == nil || !Survey.isConnectedToNetwork() {
			completion(.networkNotAvailable)
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

	func print(_ log: String) {
		if Survey.verbose {
			debugDelegate?.surveyLog(log)
			Swift.print("\(Date()) \(log)")
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

	fileprivate func _setup() {
		backgroundColor = UIColor.white
		let bar = UIView()
		bar.backgroundColor = UIColor(white: 0.96, alpha: 1)
		bar.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bar)
		bar.fullWidth()
		bar.fixAttribute(.height, value: 64)
		bar.toTheTop()
		topBar = bar

		let closeButton = CloseButton()
		closeButton.isOpaque = false
		closeButton.translatesAutoresizingMaskIntoConstraints = false
		bar.addSubview(closeButton)
		closeButton.fixAttribute(.width, value: 42)
		closeButton.fixAttribute(.height, value: 42)
		closeButton.toTheRight()
		closeButton.toTheBottom()
		self.closeButton = closeButton
		bar.isHidden = true

		let contentController = WKUserContentController()
		SurveyView.events.forEach { contentController.add(self, name: $0) }
		let configuration = WKWebViewConfiguration()
		configuration.userContentController = contentController
		configuration.allowsInlineMediaPlayback = true
		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(webView)
		addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: bar, attribute: .bottom, multiplier: 1, constant: 0))
		webView.toTheBottom()
		webView.fullWidth()
		webView.scrollView.showsVerticalScrollIndicator = false
		webView.scrollView.showsHorizontalScrollIndicator = false
		self.webView = webView
	}

	deinit {
		SurveyView.events.forEach { webView.configuration.userContentController.removeScriptMessageHandler(forName: $0) }
	}

	func createSurveyWall(_ survey: Survey) {
		self.survey = survey
		let bundle = Bundle(for: classForCoder)
		if let templateFile = bundle.url(forResource: "template", withExtension: "html"),
			let template = try? String(contentsOf: templateFile, encoding: String.Encoding.utf8) {
			let loader = (try! Data(contentsOf: bundle.url(forResource: "survata-spinner", withExtension: "png")!)).base64EncodedString(options: [])
			let json = survey.option.optionForJS(survey.zipcode)
			let optionString = jsonString(json)
			let html = template
				.replacingOccurrences(of: "[PUBLISHER_ID]", with: survey.option.publisher)
				.replacingOccurrences(of: "[OPTION]", with: optionString)
				.replacingOccurrences(of: "[LOADER_BASE64]", with: loader)
			survey.print("loading survata option = \(optionString)...")
			webView.loadHTMLString(html, baseURL: URL(string: "http://192.168.0.87"))
		}
	}

	func on(_ event: String, closure: @escaping (AnyObject) -> ()) {
		if var _events = events[event] {
			_events.append(closure)
		} else {
			events[event] = [closure]
		}
	}

	func startInterview() {
		webView.evaluateJavaScript("var _ = startInterview();", completionHandler: nil)
	}

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		survey?.print("Survata.js on event '\(message.name)'")
		events[message.name]?.forEach { $0(message.body as AnyObject) }
	}
}

class SurveyViewController: UIViewController {
	weak var surveyView: SurveyView!
	weak var survey: Survey!

	var margin: CGFloat = 0
	var onCompletion: ((SVSurveyResult) -> ())?

	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .all
	}

	var timer: DispatchSourceTimer!

	override func viewDidLoad() {
		view.backgroundColor = UIColor.clear
		let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
		view.addSubview(blur)
		blur.frame = view.bounds
		blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		let surveyView = SurveyView(frame: .zero)
		surveyView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(surveyView)
		fullWidth(surveyView, margin: margin)
		fullHeight(surveyView, margin: margin)
		surveyView.layer.borderColor = UIColor(white: 0.2, alpha: 1).cgColor
		surveyView.layer.borderWidth = 1
		self.surveyView = surveyView

		surveyView.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
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
					surveyView.topBar?.isHidden = false
					//continue
				} else {
					self?.dismiss(animated: true, completion: nil)
					self?.onCompletion?(.creditEarned)
				}
			} else if !testing && notAPreview {
				self?.dismiss(animated: true, completion: nil)
				self?.onCompletion?(.noSurveyAvailable)
			}
		}
		surveyView.on("interviewComplete") {[weak self] _ in
			self?.dismiss(animated: true, completion: nil)
			self?.onCompletion?(.completed)
		}

		//never seen this happening
		surveyView.on("interviewSkip") {[weak self] _ in
			self?.dismiss(animated: true, completion: nil)
			self?.onCompletion?(.skipped)
		}

		surveyView.on("noSurveyAvailable") {[weak self] _ in
			self?.dismiss(animated: true, completion: nil)
			self?.onCompletion?(.noSurveyAvailable)
		}

		surveyView.createSurveyWall(survey)
		timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.main)
		timer.resume()
		timer.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.seconds(2), leeway: DispatchTimeInterval.seconds(0))
		timer.setEventHandler {[weak self] in
			if !Survey.isConnectedToNetwork() {
				self?.dismiss(animated: true, completion: nil)
				self?.onCompletion?(.networkNotAvailable)
			}
		}
	}

	override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
		timer.cancel()
		view.removeFromSuperview()
		removeFromParentViewController()
	}

	deinit {
		if timer != nil {
			timer.cancel()
		}
	}

	func close() {
		dismiss(animated: true, completion: nil)
		onCompletion?(.canceled)
	}
}
