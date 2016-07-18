## 1. Requirements

1. We assume that you already have a project in Xcode and that this project is opened in Xcode 7 or later.
2. The SDK supports iOS 8.0 and later.

## Installation
### CocoaPods

We recommend integrating Survata into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Survata', :git => 'git@github.com:Survata/survata-ios-public-sdk.git', :commit => '0cd312b' # Use latest commit
```

Then, run the following command:

```bash
$ pod install
```

And add `import Survata` to the top of the files using Survata

### Carthage

To intergrate Survata into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "survata/survata-ios-public-sdk" >= 1.0
```

And add `import Survata` to the top of the files using Survata


## Examples

Please check out [demo app](https://github.com/survata/survata-ios-demo-app) for a real-life demo.

Here is a brief demo to bind Survey to a button:

### Step 1
You can display it in your project however you like, but I chose to use a UIView, an ActivityIndicatorView, and a Button in order to trigger the creation of the survey. 
```swift
    @IBOutlet weak var surveyMask: GradientView!
    @IBOutlet weak var surveyIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scoreButton: UIButton!
```
### Step 2
Then, I used the function "createSurvey()" to create the survey. Initialize it with the property publisherId. 

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

####2. SECOND WAY: Using a default survey with SurveyDebugOption, "preview" property & demo survey preview id 

There is another class called **SurveyDebugOption** (subclass of SurveyOption) in the SDK. It has a property called **preview** that allows you to set a default preview Id for a survey (thus, have a specific survey). We have a default short demo survey with just 3 questions at Survata that is perfect for testing that uses the preview id **5fd725139884422e9f1bb28f776c702d**. Here's some code as to show you how to integrate it: 

```swift
    let option = SurveyDebugOption(publisher: Settings.publisherId)
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
            if(counter1 + 20 <= 100){
                counter1 += 20
            } else {
                counter1 = 100
            }
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
