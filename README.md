# Swain's To-Do List app

The app's architecture can be broken down into three primary components: Models, Views, and ViewModels. Descriptions below.






### Models
The app's models consist of the backing data/information around which logic is performed. Examples in this app: `Database`  and its implementation `CoreDataDatabase`

### View Models
View Models serve as the bridge between the Models and the Views. In general, every unique screen of the app should have its own ViewModel. ViewModels are responsible for initially loading data, and transforming communication from the Model -> View and View -> Model. Interactions with ViewModels fall strictly into either Inputs from the View (in the form of ViewModel object methods) or Outputs to the View (in the form of settable handler closures).

They are uniformly declared as in this example:

```swift
protocol SampleViewModelInputs: class {
    /// Call when the user taps the button.
    func userTappedButton()
}

protocol SampleViewModelOutputs: class {
    /// Outputs when the provided String should be displayed to the user.
    var displayMessage: ((String) -> Void)? { get set }
}

protocol SampleViewModelType: class {
    var inputs: SampleViewModelInputs { get }
    var outputs: SampleViewModelOutputs { get }
}

final class SampleViewModel: SampleViewModelInputs, SampleViewModelOutputs, SampleViewModelType {
    var inputs: SampleViewModelInputs { return self }
    var outputs: SampleViewModelOutputs { return self }

    // MARK: - Private Properties

    /// Example property that may change based on app conditions, Model information, etc.
    private var shouldDisplayMessage: Bool = false

    init(...) { }

    // MARK: - Outputs
    var displayMessage: ((String) -> Void)?

    // MARK: - Inputs
    func userTappedButton() {
        if shouldDisplayMessage {
            self.outputs.displayMessage?("Sample message!")
        }
    }
}
```

Initially, this code pattern may seem a bit repetitive. However, I would argue that the clarity and ease of understanding it provides is worth the extra lines. At first glance, we can immediately see all of the ways in which the user can interact with the associated screen (in the form of Inputs), and all of the ways in which the View can change (in the form of Outputs).

### Views
View objects in the app are, generally, `UIViewController` subclasses, like `AllListsViewController`. A View has only two jobs:

1. Gather user input, and pass it along to its associated ViewModel's `inputs`.
2. Respond to its associated ViewModel's `outputs` by assigning closures to each before the end of its `viewDidLoad` override.

Example interaction from a `UIViewController`:

```swift
final class SampleViewController: UIViewController {

    let viewModel: SampleViewModelType

    init(viewModel: SampleViewModelType) {
        self.viewModel = viewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.outputs.displayMessage = displayMessage
    }

    var displayMessage: (String) -> Void { 
        return { [weak self] message in 
            self?.label.text = message
        }
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        self.viewModel.inputs.userTappedButton()
    }
}
```
Note that no decisioning happens in the view controller--it's only responsibility is to respond to outputs, and pass along inputs.

## Architecture Primary Benefits
#### Testability
While this project does not have unit tests (due to time constraints), the decoupling between the ViewModel and the View objects allow both to be tested independently. The clearly defined API contracts between a ViewModel and its view allow for thorough testing, and high code coverage.

#### Ease of Understanding
The clearly defined Input/Output protocols allow a developer to quickly understand "what actually happens" on a given screen, which can often be almost half the battle when working with new code.
