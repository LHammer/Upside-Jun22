//
//  RequestUserAccessVC.swift
//  Upside
//
//  Created by Luke Hammer on 4/30/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth


/*
 
 changes for git repo test.
 
 */

class RequestUserAccessVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var db = Firestore.firestore()
    
    @IBOutlet weak var validUserHolder: UIView!
    @IBOutlet weak var newUserHolder: UIView!
    
    @IBOutlet weak var resetPasswordButton: StandardButton!
    @IBOutlet weak var requestAccessButton: StandardButton!
    
    @IBOutlet weak var resetEmailTF: UITextField!
    
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var roleTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resetPasswordButton.setColorSchemes(scheme: .blackWhite)
        self.requestAccessButton.setColorSchemes(scheme: .blackWhite)
        
        self.setupDefualtNavigationBar()
        
        self.validUserHolder.layer.cornerRadius = 5.0
        self.newUserHolder.layer.cornerRadius = 5.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        self.setupTextFeildDelegates()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupTextFeildDelegates() {
        self.resetEmailTF.delegate = self
        self.firstNameTF.delegate = self
        self.lastNameTF.delegate = self
        self.roleTF.delegate = self
        self.emailTF.delegate = self
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if textField == self.resetEmailTF { // Switch focus to other text field
            print("send password reset,")
            
            self.resetPassword()
            
        } else if textField == self.firstNameTF {
            self.lastNameTF.becomeFirstResponder()
        } else if textField == self.lastNameTF {
            self.roleTF.becomeFirstResponder()
        } else if textField == self.roleTF {
            self.emailTF.becomeFirstResponder()
        } else if textField == self.emailTF {
            print("dismiss keyboard & request access.")
            
            self.submitRequestAccessForm()
            
        }
            
        return true
    }
    
    private func resetPassword() {
        
        let email = self.resetEmailTF.text?.lowercased() ?? ""
        
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            
            if let error = err {
                // Create new Alert
                let dialogMessage = UIAlertController(title: "Error",
                                                      message: error.localizedDescription,
                                                      preferredStyle: .alert)
                
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: { (action) -> Void in
                    print("Ok button tapped")
                 })
                
                //Add OK button to a dialog message
                dialogMessage.addAction(ok)
                // Present Alert to
                self.present(dialogMessage, animated: true,
                             completion: nil)
            } else {
                // Create new Alert
                let dialogMessage = UIAlertController(title: "Success",
                                                      message: "An email has been sent to your email to reset your password.",
                                                      preferredStyle: .alert)
                
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: { (action) -> Void in
                    print("Ok button tapped")
                 })
                
                //Add OK button to a dialog message
                dialogMessage.addAction(ok)
                // Present Alert to
                self.present(dialogMessage, animated: true,
                             completion: nil)
            }
        }
    }
    
    @objc
    func keyboardWillShow(notification:NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 20
        scrollView.contentInset = contentInset
    }

    @objc
    func keyboardWillHide(notification:NSNotification) {
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    @IBAction func sendPasswordReset(_ sender: Any) {
        self.resetPassword()
    }
    
    private func requestAccessFormComplete() -> (complete: Bool, errorDescription: String) {
        
        if firstNameTF.text == "" || firstNameTF.text == nil {
            return (complete: false, errorDescription: "First name is required.")
        }
        
        if lastNameTF.text == "" || lastNameTF.text == nil {
            return (complete: false, errorDescription: "Last name is required.")
        }
        
        if roleTF.text == "" || roleTF.text == nil {
            return (complete: false, errorDescription: "Enter a valid 'role' to continue.")
        }
        
        if emailTF.text == "" || emailTF.text == nil {
            return (complete: false, errorDescription: "Enter a valid 'email' to continue.")
        }
        
        if isValidEmail(emailTF.text!) == false {
            let err = "'" + emailTF.text! + "' isn't a valid email address."
            return (complete: false, errorDescription: err)
        }
        
        return (complete: true, errorDescription: "n/a")
    }
    
    private func submitRequestAccessForm() {
        
        
        let formCheck = self.requestAccessFormComplete()
        
        if formCheck.complete == false {
            // Create new Alert
            let dialogMessage = UIAlertController(title: "Error",
                                                  message: formCheck.errorDescription,
                                                  preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK",
                                   style: .default,
                                   handler: { (action) -> Void in
                print("Ok button tapped")
             })
            
            //Add OK button to a dialog message
            dialogMessage.addAction(ok)
            // Present Alert to
            self.present(dialogMessage, animated: true,
                         completion: nil)
        
        } else { // form has all data required - can safely create the object.
            
            let ref = db.collection("requesting_users")
            let doc = ref.document()
            
            let req = UserRequestModel(id: doc.documentID,
                                       email: emailTF.text!.lowercased(),
                                       firstName: firstNameTF.text!,
                                       lastName: lastNameTF.text!,
                                       role: roleTF.text!,
                                       timestamp: Date().timeIntervalSince1970,
                                       deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "not available",
                                       status: "pending",
                                       firebaseUID: doc.documentID)
            do {
                let _ = try doc.setData(from: req)
                // Create new Alert
                let dialogMessage = UIAlertController(title: "Success",
                                                      message: "Your request has been submitted to an administrator. You will be notified when approved or rejected.",
                                                      preferredStyle: .alert)
                
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: { (action) -> Void in
                    
                    
                    self.dismiss(animated: true)
                 })
                //Add OK button to a dialog message
                dialogMessage.addAction(ok)
                // Present Alert to
                self.present(dialogMessage, animated: true,
                             completion: nil)
            } catch {
                // Create new Alert
                let dialogMessage = UIAlertController(title: "Error",
                                                      message: "Unable to write to database. Please try again soon.",
                                                      preferredStyle: .alert)
                
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: { (action) -> Void in
                    print("Ok button tapped")
                 })
                
                //Add OK button to a dialog message
                dialogMessage.addAction(ok)
                // Present Alert to
                self.present(dialogMessage, animated: true,
                             completion: nil)
            }
        }
        
    }
    
    
    @IBAction func requestUserAccessPressed(_ sender: Any) {
        self.submitRequestAccessForm()
    }
}
