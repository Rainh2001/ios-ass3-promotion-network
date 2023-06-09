import UIKit
import GoogleMaps

class CreatePostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var popUpButton: UIButton!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var moneySavedField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var addressField: UITextField!
    var category: String!

    private var realmManager = RealmManager.shared

    var latitude: String = ""
    var longitude: String = ""
    var address: String?
    var createdPost: Post?
    let textViewPlaceholder = "Explain the details and any useful tip to get the best deal. The first sentence will be the title of the post! "

    override func viewDidLoad() {
        // Only allow numbers in money saved field
        moneySavedField.delegate = self
        super.viewDidLoad()
        setupPopUpButton()
        addressField.isEnabled = false
        descriptionField.text = textViewPlaceholder
        descriptionField.textColor = UIColor.darkGray
        descriptionField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addressField.text = address

    }

    // Add options to the pop up button menu and a handler to handle selection
    func setupPopUpButton() {
        let popUpButtonClosure = { (action: UIAction) in
            self.category = action.title
        }
        popUpButton.menu = UIMenu(children: Category.allCases.map {
            UIAction(title: $0.rawValue, handler: popUpButtonClosure) })
        self.category = popUpButton.menu?.children.first?.title ?? ""

        popUpButton.showsMenuAsPrimaryAction = true
        applyBorderStylingToButton(buttons: [popUpButton])

    }


    // When button is pressed, show image picker
    @IBAction func imagePicker(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }

    // Set post image from image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        postImage.image = image
        dismiss(animated: true)
    }

    //function for the text view
    internal func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.darkGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    //function to display placeholder if nothing is in the text view
    internal func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = textViewPlaceholder
            textView.textColor = UIColor.darkGray
        }
    }

    // Only allow numbers in money saved field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }

    //select an address
    @IBAction func selectAddressPressed(_ sender: Any) {
        pushToMapSearchViewController()
    }

    //go to map search view controller
    func pushToMapSearchViewController() {
        let vc = storyboard?.instantiateViewController(identifier: "MapSearchViewController") as! MapSearchViewController
        vc.vc = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    //create the post
    @IBAction func createButtonPressed(_ sender: Any) {
        //assign the fields
        guard let chosenCategory = category else { return }
        guard var text = descriptionField.text else { return }
        if descriptionField.textColor == UIColor.darkGray { text = "" } //placeholder
        guard let address = address else { textFieldErrorAction(field: addressField, msg: "Address can't be empty"); return }
        guard let moneySaved = moneySavedField.text else { return }

        let newPost = Post(text: text, address: address, latitude: latitude, longitude: longitude, moneySaved: Double(moneySaved) ?? 0, category: Category(rawValue: chosenCategory)!) //create new post
    
        _ = newPost.createPost(image: postImage.image, completion: postSucessfullyCreated) //saves the info to the db and the image to awss3. Goes to view post when completed.
    
        createdPost = newPost
        
        guard let _ = postImage.image else { // if no image was available go to the view post page.
            self.performSegue(withIdentifier: "postCreateSegue", sender: self)
            return
        }
    }

    //once the post is created push to the post view controller
    func postSucessfullyCreated(_ response: Any?, _ error: Error?) -> Void {
        if let _ = error {
            createdPost?.imageKey = ""
            print("An error occured uploading the image")
            return
        }
        self.performSegue(withIdentifier: "postCreateSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "postCreateSegue") {
            let viewPost = segue.destination as! ViewPostViewController
            viewPost.post = createdPost ?? nil //send the post as a variable in the viewpost controller
            resetPost()
        }
    }
    
    func resetPost(){
        createdPost = nil
        postImage.image = nil
        moneySavedField.text = ""
        descriptionField.text = ""
        address = ""
    }

}

