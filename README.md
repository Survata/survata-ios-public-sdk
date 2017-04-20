## 1. Requirements

1. We assume that you already have a project in Xcode and that this project is opened in Xcode 7 or later.
2. The SDK supports iOS 8.0 and later.

## Installation
### CocoaPods

We recommend integrating Survata into your Xcode project using CocoaPods, specify it in your `Podfile`:
(this repo is written in Swift 3)
```ruby
pod 'Survata', :git => 'git@github.com:Survata/survata-ios-public-sdk.git'
```
*NOTE
If you are looking for the sdk written in Swift 2.3, use this snippet in the `Podfile`:
```ruby
pod 'Survata', :git => 'git@github.com:Survata/survata-ios-public-sdk.git', :branch => 'swift-2.3'
```

Then, run the following command:

```bash
$ pod install
```

If changes have been made to the survata-public-ios-sdk, to get the latest changes.
run the following commands:
```bash
$ pod repo remove master
$ pod setup
$ pod install
```

And add `import Survata` to the top of the files using Survata

### Carthage

1. To integrate Survata into your Xcode project using Carthage, specify it in your `Cartfile`:
    ```ogdl
    github "Survata/survata-ios-public-sdk" "master"
    ```

2. Run the following command so that it will build the Survata scheme. (Make sure that it is pulling the most recent commit from 'survata-ios-public-sdk')
    ```
    > carthage update
    ```
NOTE: if it is fetching an outdated commit, remove line mentioning Survata in Cartfile.resolved file, the 'survata-ios-public-sdk' folder in Carthage/Checkouts, and the Survata.framework/.dSYM in Carthage/Build/iOS. After that, run carthage update again.

3. Follow [these steps](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos) in Xcode

4. After adding the new Survata framework into Xcode, add `import Survata` to the top of the files using Survata


## Examples

Please check out [demo app](https://github.com/survata/survata-ios-demo-app) for a real-life demo.

Here is a brief demo to bind Survey to a button:

```swift
class ViewController: UIViewController {
    weak var surveyButton: UIButton!

    var survey: Survey!

    func checkSurvey() {
		let publisher = ....
		let option = SurveyOption(publisher: publisher)
		survey = Survey(option: option)
		survey.create { availability in
            if availability == .Available {
                surveyButton.hidden = false
            }
        }
    }

    // action for surveyButton
    func showSurvey() {
        survey.createSurveyWall { result in
            if result == .Completed {
                surveyButton.hidden = true
            }
        }
    }
}
```

Here's another longer demo that goes more in-depth (I highly recommend you read both).

### Step 1
You can display it in your project however you like, but I chose to use a UIView, an ActivityIndicatorView, and a Button in order to trigger the creation of the survey.
```swift
    @IBOutlet weak var surveyMask: GradientView!
    @IBOutlet weak var surveyIndicator: UIActivityIndicatorView!
    @IBOutlet weak var surveyButton: UIButton!
```
### Step 2
Then, I used the function "createSurvey()" to create the survey. Initialize it with the property publisherId. It also checks if the survey is available.

```swift
func createSurvey() {
        if created { return }
        let option = SurveyOption(publisher: Settings.publisherId)
        option.contentName = Settings.contentName // optional
        survey = Survey(option: option)

        survey.create {[weak self] result in
            self?.created = true
            switch result {
            case .Available:
                self?.showSurveyButton()
            default:
                self?.showFull()
            }
        }
    }
```

#### Explaining contentName
The contentName property is optional. It enforces that there is one survey per respondent per contentName. For example, if using a survey to unlock a level in a game or an e-book, it allows the publisher to offload enforcing that unlocking to be permanent onto us.

For example, if there's a game and there's a level 7. If a person playing the game has already earned the survey for level 7, if they request a survey for level 7 again, it shows that they already earned it.

If you're not doing something like unlocking a level, you don't need to use contentName. If you want to limit for example, one survey per day, you could use something as the date for the contentName.

#### IMPORTANT NOTE

There is a frequency cap on how many surveys we allow one day for a specific IP address. Thus while testing/developing, it might be frustrating to not see surveys appear after a couple of tries. You can bypass this in two ways.

####1. FIRST WAY: Using "testing" property

There is a property called **testing** which is a boolean that can be set to true. Below is a snippet of the previous code above that includes the testing property. This will bring up real surveys (that might take very long to answer, so look at the second way), but your responses are not recorded.

```swift
    let option = SurveyOption(publisher: Settings.publisherId)
    option.testing = true
```

####2. SECOND WAY: Using a default survey with SurveyOption, "preview" property & demo survey preview id

There is a property called **preview** that allows you to set a default preview ID for a survey (thus, have a specific survey). We have a default short demo survey with just 3 questions at Survata that is perfect for testing that uses the preview id **5fd725139884422e9f1bb28f776c702d**. Here's some code as to show you how to integrate it:

```swift
    let option = SurveyOption(publisher: Settings.publisherId)
    option.preview = "5fd725139884422e9f1bb28f776c702d"
```

### Step 3

As you can probably tell, I created a Settings.swift file to store my information. This is part of it.

```swift
struct Settings {
	static var publisherId: String! = "survata-test"
	static var previewId: String! = "46b140a358cd4fe7b425aa361b41bed9"
	static var contentName: String!
	static var forceZipcode: String!
	static var sendZipcode: Bool = true
}
```

### Step 4
If the survey is created successfully, I triggered the showSurveyButton() and showFull() functions to display them.

```swift
func showFull() {
       surveyMask.hidden = true
	}
func showSurveyButton() {
        surveyMask.hidden = false
        surveyButton.hidden = false
        surveyIndicator.stopAnimating()
        }
```
### Step 5
After that, when the button is displayed, I defined a function called startSurvey() that will display the survey once the button is tapped (createSurveyWall()). It also returns the events -- COMPLETED, CANCELED, CREDIT_EARNED, NETWORK_NOT_AVAILABLE, and NO_SURVEY_AVAILABLE (ex. people under 13, people taking multiple surveys and being capped at our frequency cap).

```swift
 @IBAction func startSurvey(sender: UIButton) {
        if (survey != nil){
            survey.createSurveyWall { result in
                delay(2) {
                    SVProgressHUD.dismiss()
                }
                switch result {

                case .Completed:
                    SVProgressHUD.showInfoWithStatus("Completed")
                case .Canceled:
                    SVProgressHUD.showInfoWithStatus("Canceled")
                case .CreditEarned:
                    SVProgressHUD.showInfoWithStatus("Credit earned")
                case .NetworkNotAvailable:
                    SVProgressHUD.showInfoWithStatus("Network not available")
                case .Skipped:
                    SVProgressHUD.showInfoWithStatus("Skipped")
                case .NoSurveyAvailable:
                    SVProgressHUD.showInfoWithStatus("No survey available")
                default:
                    SVProgressHUD.showInfoWithStatus("no opp")
                }
            }
        } else {
            print("survey is nil")
        }
    }
```

## Submitting your App

when submitting to AppStore, please select Yes to the question “Does this app use the Advertising Identifier (IDFA)?” and check “Serve advertisement within the app” in the second form box.

![IDFA](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Art/IDFA_2x.png)

![IDFA-Submitting](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Art/11IDFA-Submitting_2x.png)
