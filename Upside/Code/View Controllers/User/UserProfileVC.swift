//
//  UserProfileVC.swift
//  Upside
//
//  Created by Luke Hammer on 4/29/22.
//



// MARK: TODO
/*
 - add UI warning errors
 - upload to GitHUB
 */

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class UserProfileVC: UIViewController {
    
    private struct CellData {
        let heading: String
        let content: String
    }
    
    private var tableViewData: [CellData]? {
        didSet {
            if self.tableViewData != nil {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var usersNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profilePictureButton: UIButton!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    private var db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    let IMAGE_DOWNLOADED_TAG = 999999
    
    private var fetchedProfileDataImages = [ProfileImageModel]() { // data only, not the images themselves
        didSet {
            
            if fetchedProfileDataImages.count > 0 {
                if let _ = fetchedProfileDataImages[0].url { // list is already ordered from the firebase pull.
                    self.currentProfileImageData = fetchedProfileDataImages[0]
                } else  {
                    print("There's no image to  display.")
                }
            }
        }
    }
    
    private var currentProfileImageData: ProfileImageModel? {
        didSet {
            if currentProfileImageData != nil {
                print(self.currentProfileImageData!)
                // MARK: TODO now it's time to pull image data.
                self.fetchProfileImage(urlString: currentProfileImageData!.url!)
            }
        }
    }
    
    
    private var userData: FirebaseUserModel? {
        didSet {
            if userData != nil {
                self.usersNameLabel.text = userData!.fullName ?? "---"
                self.configureTableViewDataFromCurrentUser()
                /* Remove loading spinner after image and user data is
                 downloaded. */
                
                
                // MARK: TODO - commenting out the condition for now as not all users will have images.
                //if self.profileImageView.tag == IMAGE_DOWNLOADED_TAG {
                    self.removeSpinner()
                //}
                
                
            }
        }
    }
    
    @IBOutlet weak var signOutButton: StandardButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Primary call to data base.
        self.authCheck()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        self.signOutButton.setColorSchemes(scheme: .aquaWhite)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        UINib(nibName: "UserProfileVC", bundle: nil).instantiate(withOwner: self, options: nil)
    }
    
    private func configureTableViewDataFromCurrentUser() {
        if userData != nil {
            let email = CellData(heading: "email:", content: userData?.email ?? "not available")
            let role = CellData(heading: "role:", content: userData?.role ?? "not available")
            let department = CellData(heading: "department:", content: userData?.department ?? "not available")
            let team = CellData(heading: "team:", content: "not available")
            let timeZone = CellData(heading: "time-zone:", content: userData?.timeZoneID ?? "not available")
            self.tableViewData = [email, role, department, team, timeZone]
        }
    }
    
    // MARK: TODO Should be a global function
    func showUserLoginVC(autoFillPassword: Bool) {
        let rootViewController = UserLoginVC()
        rootViewController.delegate = self
        rootViewController.autoBiometricCheckIsOn = autoFillPassword
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.isModalInPresentation = true // prevent drag down form option
        rootViewController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    // MARK: Primary call to data base METHOD
    private func authCheck() {
        
        self.showSpinner(onView: self.view) // show spinner - downloading begining
        
        if Auth.auth().currentUser != nil { // do stuff
            self.getUserData()
            self.fetchCurrentProfileImage()
        } else { // show user login
            self.showUserLoginVC(autoFillPassword: true)
            self.removeSpinner() // remove spinner
        }
    }
    
    private func signOutUser() {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.showUserLoginVC(autoFillPassword: false)
            self.removeSpinner() // remove incase it hasn't been removed yet, shouldn't be called.
        } catch let signOutError as NSError {
            // Create new Alert
            let dialogMessage = UIAlertController(title: "Error",
                                                  message: signOutError.localizedDescription + "(\n) (\n) Unable to log out user. Please try again soon.",
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
    
    private func removeDataFromTabBarVCs() {
        if let tabBarController = tabBarController {
            
            if let summaryVC = tabBarController.viewControllers![0] as? UserCallSummaryVC {
                summaryVC.removeData()
            }
            
            //get the controller you need from
            //tabBarController.viewControllers
            //and do whatever you need
        }
    }
    
    
    @IBAction func logoutPressed(_ sender: Any) {
        
        
        
        self.signOutUser()
        self.tableViewData?.removeAll()
        self.usersNameLabel.text = "---"
        self.profileImageView.image = UIImage(named: "profile_silhouette_aqua_large")
        
        // self.removeDataFromTabBarVCs()
        
        self.tableView.reloadData()
    }
    
    
    @IBAction func editProfilePictureTapped(_ sender: Any) {
        let vc = ProfileImagePickerVC()
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    // MARK: TODO Make global function.
    private func convertToGrayScale(image: UIImage) -> UIImage {

        // Create image rectangle with current image width/height
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)

        // Grayscale color space
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = image.size.width
        let height = image.size.height

        // Create bitmap content with current image size and grayscale colorspace
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        // Draw image into current context, with specified rectangle
        // using previously defined context (with grayscale colorspace)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
            context?.draw(image.cgImage!, in: imageRect)
        let imageRef = context!.makeImage()

        // Create a new UIImage object
        let newImage = UIImage(cgImage: imageRef!)

        return newImage
    }
    
    private func fetchCurrentProfileImage() {

        if let authUID = Auth.auth().currentUser?.uid {

            // get the last, approved image.
            let query = db.collection("profile_images")
                .whereField("uid", isEqualTo: authUID)
                .whereField("status", isEqualTo: "approved")
                .order(by: "timestamp", descending: true).limit(to: 1)

            // add listener to quary so image updates
            query.addSnapshotListener { (querySnapshot, error) in
                
                guard let docs = querySnapshot?.documents else {
                    print("aoeiubfeoqwi error = no documents.")
                    return
                }
                self.fetchedProfileDataImages = docs.compactMap { (queryDocumentSnapshot) -> ProfileImageModel? in
                    
                    print("rerutning stuff.")
                    return try? queryDocumentSnapshot.data(as: ProfileImageModel.self)
                }
            }
        } else {
            print("need a valid user to be signed in.")
        }
    }
    
    private func fetchProfileImage(urlString: String)  {
        
        if let url = URL(string: urlString) {
            
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if error == nil {
                    
                    if data == nil {
                        print("Error, no data available.")
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            let image = UIImage(data: data!)
                            if image != nil {
                                
                                self.profileImageView.image = self.convertToGrayScale(image: image!)
                                
                                self.profileImageView.tag = self.IMAGE_DOWNLOADED_TAG // set tag so spinner can be removed if user data takes longer than the image.
                                /* Remove loading spinner after image and user data is
                                 downloaded. */
                                if self.userData != nil {
                                    self.removeSpinner()
                                }
                                
                            } else {
                                print("Error converting data to an image.")
                            }
                        }
                    }
                } else {
                    print("error: ", error!.localizedDescription)
                }
            }
            task.resume()
            
        } else {
            print("Error, valid url could not be made from string: ", urlString)
        }
    }
    
    
    private func getUserData() {
        if let userID = Auth.auth().currentUser?.uid { // Has logged in user.
            let docRef = db.collection("users").document(userID)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    do {
                        self.userData = try document.data(as: FirebaseUserModel.self)
                    } catch {
    
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
                    }
                } else {

                    // Create new Alert
                    let dialogMessage = UIAlertController(title: "Error",
                                                          message: "Document does not exist",
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
        } else {  // Couldn't find user with uid.
    
            // Create new Alert
            let dialogMessage = UIAlertController(title: "Error",
                                                  message: "No user ID.",
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


// MARK: TableView Extension
extension UserProfileVC: PassLoginSuccess {
    func passStatus(_ stat: Bool) {
        if stat == true {
            //self.getUserData()
            
            self.authCheck()
        } else {
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
}

// MARK: TableView Extension
extension UserProfileVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("StandardCell", owner: self, options: nil)?.first as! StandardCell
        cell.heading = tableViewData?[indexPath.row].heading ?? "---"
        cell.content = tableViewData?[indexPath.row].content ?? "---"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
}


