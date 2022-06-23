//
//  UserLoginVC.swift
//  Upside
//
//  Created by Luke Hammer on 4/30/22.
//

import UIKit
import FirebaseAuth
import LocalAuthentication
import KeychainSwift


protocol PassLoginSuccess: AnyObject {
    func passStatus(_ stat: Bool)
}



class UserLoginVC: UIViewController {
    
    // store user info locally
    let userDefaults = UserDefaults()
    
    var autoBiometricCheckIsOn = true
    
    weak var delegate: PassLoginSuccess?
    
    @IBOutlet weak var inputHolder: UIView!
    @IBOutlet weak var loginButton: StandardButton!
    @IBOutlet weak var forgetPasswordButton: StandardButton!
    @IBOutlet weak var newUserButton: StandardButton!
    @IBOutlet weak var emailTextFeild: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var faceIDSwitch: UISwitch!
    
    override func viewDidLoad() {
        
        
        print("view did load.")
        
        super.viewDidLoad()
        
        self.setupDefualtNavigationBar()
        self.inputHolder.layer.cornerRadius = 5.0
        
        self.loginButton.setColorSchemes(scheme: .blackWhite)
        self.forgetPasswordButton.setColorSchemes(scheme: .clearBlue)
        self.newUserButton.setColorSchemes(scheme: .aquaWhite)
        
        self.rememberMeSwitch.onTintColor = ui_active_aqua
        self.faceIDSwitch.onTintColor = ui_active_aqua
        
        self.rememberMeSwitch.addTarget(self, action: #selector(biometricSwitchChanged), for: UIControl.Event.valueChanged)
        self.faceIDSwitch.addTarget(self, action: #selector(rememberMeSwitchChanged), for: UIControl.Event.valueChanged)
        
        
        self.updateSwitchersWithLocallyStoredData()
        
        
        if rememberMeSwitch.isOn == true { // load username, wait to load password with biometrics.
            self.autoLoadUsernameDetails()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        if self.shouldAutoCheckBiometrics() == true {
            self.authenticBiometrics()
        }
        
        self.autoBiometricCheckIsOn = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func loginPressed(_ sender: Any) {
        self.login(email: emailTextFeild.text?.lowercased() ?? "",
                   password: passwordTextField.text ?? "")
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        self.resetPassword()
    }
    
    @IBAction func newUserPressed(_ sender: Any) {
        self.showNewUserRequestVC()
    }


    @IBAction func deleteContentsPressed(_ sender: Any) {
        self.emailTextFeild.text = ""
        self.passwordTextField.text = ""
        self.emailTextFeild.becomeFirstResponder()
    }
    
    @IBAction func faceTimePressed(_ sender: Any) {
        self.authenticBiometrics()
    }
    
    private func resetPassword() {
        
        let email = emailTextFeild.text?.lowercased() ?? ""
        
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
    
    private func shouldAutoCheckBiometrics() -> Bool {
        if faceIDSwitch.isOn == true {
            if autoBiometricCheckIsOn == true {
                let keychain = KeychainSwift()
                let currentSecureUsername = keychain.get("username")
                if emailTextFeild.text?.lowercased() == currentSecureUsername?.lowercased() {
                    return true
                }
            }
        }
        return false
    }
    
    private func login(email: String, password: String) {
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error, let _ = AuthErrorCode(rawValue: error._code) {
                
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
                
                // Add OK button to a dialog message
                dialogMessage.addAction(ok)
                // Present Alert to
                self.present(dialogMessage, animated: true,
                             completion: nil)
            } else {
                
                self.delegate?.passStatus(true) // pass back true back
                
                // store details in keychain if they want to be remembered.
                // MARK: TODO add remember logic.
                // MARK: TODO add validation of password logic - minimum requirements.
                if self.rememberMeSwitch.isOn == true { // store user details securley. Only done when loging in.
                    self.encryptAndLocallyStoreUsernameAndPassword(password: self.passwordTextField.text!,
                                                                   username: self.emailTextFeild.text!)
                } else { // delete any stored sensitive data.
                    self.deleteEncryptedLoginDetails()
                }

                self.dismiss(animated: true) {
                    print("login page dismissal complete.")
                }
            }
        }
    }
    
    private func storeUserPreferences() {
        let rememberMe = self.rememberMeSwitch.isOn
        let biometrics = self.faceIDSwitch.isOn
        self.userDefaults.set(rememberMe, forKey: "remember")
        self.userDefaults.set(biometrics, forKey: "biometrics")
        
    }
    
    private func updateSwitchersWithLocallyStoredData() {
        if let rememberMeStored = userDefaults.value(forKey: "remember") as? Bool {
            self.rememberMeSwitch.setOn(rememberMeStored,
                                        animated: false)
        }
        
        if let biometricsStored = userDefaults.value(forKey: "biometrics") as? Bool {
            self.faceIDSwitch.setOn(biometricsStored,
                                    animated: false)
        }
    }
    
    
    private func showNewUserRequestVC() {
        let rootViewController = RequestUserAccessVC()
        let navController = UINavigationController(rootViewController: rootViewController)
        self.present(navController,
                     animated: true,
                     completion: nil)
    }
    
    
    
    @objc
    private func biometricSwitchChanged(switch: UISwitch) {
        self.storeUserPreferences()
    }
    
    
    // when turned off, delete any sensitive user info.
    // should only be added back once loggin in.
    @objc
    private func rememberMeSwitchChanged(rememberMeSwitchChanged: UISwitch) {
        self.storeUserPreferences()
        if rememberMeSwitchChanged.isOn == false { // if moved to don't remember, delete sensitive data.
            let keychain = KeychainSwift()
            keychain.delete("password")
            keychain.delete("username")
        }
    }
}


// MARK: Keychain Managment

extension UserLoginVC {
    
    
    private func autoLoadUsernameDetails() {
        let keychain = KeychainSwift()
        self.emailTextFeild.text = keychain.get("username")
    }
    
    private func autoLoadPasswordDetails() {
        let keychain = KeychainSwift()
        self.passwordTextField.text = keychain.get("password")
    }
    
    
    private func deleteEncryptedLoginDetails() {
        let keychain = KeychainSwift()
        keychain.delete("password")
        keychain.delete("username")
    }
    
    // Method not designed to be safe - need to pass in confirmed / valid values.
    // perhaps enhance method to be safe.
    private func encryptAndLocallyStoreUsernameAndPassword(password: String, username: String) {
        let keychain = KeychainSwift()
        keychain.set(password, forKey: "password")
        keychain.set(username, forKey: "username")
    }
}



// MARK: Biometrics login

extension UserLoginVC {
    
    
    private func authenticBiometrics() {
        
        // https://www.hackingwithswift.com/read/28/4/touch-to-activate-touch-id-face-id-and-localauthentication
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) { // has Biometrics
            
            
            let reason = "Identify yourself!" // for touch ID only. FaceID is in plist! 'Privacy - Face ID Usage Description'
            
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async { // put back on the main thread for UI
                    if success {
                        self?.unlockWithSuccessfulBiometrics()
                    } else { // error attempting, such as reflective sunglasses for
                        let ac = UIAlertController(title: "Authentication failed",
                                                   message: "You could not be verified; please try again.",
                                                   preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK",
                                                   style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else { // doesn't have biometrics
            let ac = UIAlertController(title: "Biometrics unavailble",
                                       message: "Your device is not configured for biometric authentication.",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK",
                                       style: .default))
            present(ac, animated: true)
        }
    }
    
    
    private func unlockWithSuccessfulBiometrics() {

        let keychain = KeychainSwift()
        let password = keychain.get("password")
    
        self.passwordTextField.text = password
        
        self.login(email: self.emailTextFeild.text ?? "",
                   password: self.passwordTextField.text ?? "")
    }
    
}
