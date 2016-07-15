## 1. Requirements

1. We assume that you already have a project in Xcode and that this project is opened in Xcode 7 or later.
2. The SDK supports iOS 8.0 and later.

## Installation
### CocoaPods

We recommend integration Survata into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Survata'
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
