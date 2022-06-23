//
//  ProfileImagePickerVC.swift
//  Upside
//
//  Created by Hammer, Luke on 5/14/22.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import Firebase
import FirebaseFirestoreSwift
import SwiftUI

class ProfileImagePickerVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHolderView: UIView!
    @IBOutlet weak var grayImageView: UIImageView!
    @IBOutlet weak var grayImageViewHolderView: UIView!
    
    @IBOutlet weak var selectImageBtn: StandardButton!
    @IBOutlet weak var deleteProfilePictureBtn: StandardButton!
    @IBOutlet weak var selectImageBtnTwo: UIButton!
    
    @IBOutlet weak var imageTypeSegmentControl: UISegmentedControl!
    
    private let storage = Storage.storage().reference()
    private let db = Firestore.firestore()
    
    private var fetchedProfileDataImages = [ProfileImageModel]() { // data only, not the images themselves
        didSet {
            
            if self.fetchedProfileDataImages.count > 0 {
                
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
                print("here's the most recent data points:")
                print(self.currentProfileImageData!)
                // MARK: TODO now it's time to pull image data.
                self.fetchProfileImage(urlString: currentProfileImageData!.url!)
            }
        }
    }
    
    private var uploadReadyImage: UIImage? {
        didSet {
            if self.uploadReadyImage  == nil {
                print("uploadReadyImage set to nil.")
            } else {
                print("sized image is ready for upload:")
                print(self.uploadReadyImage!)
            }
        }
    }
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.selectImageBtn.setColorSchemes(scheme: .aquaWhite)
        self.deleteProfilePictureBtn.setColorSchemes(scheme: .redWhite)
        self.imageTypeSegmentControl.backgroundColor = ui_active_aqua
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        self.fetchCurrentProfileImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        self.imageView.layer.cornerRadius = 5.0
        self.imageViewHolderView.layer.cornerRadius = 5.0
        self.grayImageViewHolderView.layer.cornerRadius = self.grayImageViewHolderView.frame.size.width / 2.0
        self.grayImageView.layer.cornerRadius = self.grayImageView.frame.size.width / 2.0
    }
    
    private func selectImage() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Photo Gallery", style: .default, handler: { (button) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
                
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (button) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
                
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = self.view // Fix so action sheet works with iPad.
        present(alert, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
            
        // MARK: TODO could/should make more effecient. no need to store all these values in memory
        let rawSelectedImage = pickedImage
        let sqauredImage = self.convertImageToMaxSqaureCenterImage(sourceImage: rawSelectedImage)
        let IMG_SIZE = 250.0 // confirm best practice image size.
        if let sizedImage = self.resizeImage(image: sqauredImage,
                                          targetSize: CGSize(width: IMG_SIZE,
                                                             height: IMG_SIZE)) { // sized image for performance / cost.
            
            //  MARK: TODO store differnet sizes? Middleware??
            // for now let's just save one image and use for all.
            let graySquaredImg = self.convertToGrayScale(image: sizedImage)
            self.imageView.image = sizedImage
            self.grayImageView.image = self.convertToGrayScale(image: graySquaredImg)
            
            
            // Key part, set the selected image ready to upload when 'saved' is tapped
            self.uploadReadyImage = sizedImage
            
        }  else {
            print("error: imagePickerController()") // no need for more error handling for MVP
        }
        
        dismiss(animated: true, completion: nil)
    }

    
    
    
    // MARK: IBOutlet methods
    @IBAction func selectImagePressed(_ sender: Any) {
        self.selectImage()
    }
    
    
    @IBAction func deleteImageTapped(_ sender: Any) {
        print("delete image - confirm if deletion worked and update ui.")
    }
    
    
    @IBAction func saveImageTapped(_ sender: Any) {
        print("attempting to save image...")
        if uploadReadyImage == nil {
             print("send ui an alert that there isn't an image ready to upload.")
        } else { // upload image to storage and save reference in profile
            // DO SOMETHING
            
            self.uploadSeletedImage(image: uploadReadyImage!)
        }
    }
    
    
    private func fetchCurrentProfileImage() {
        
        if let authUID = Auth.auth().currentUser?.uid {
            
            print("a UID: ", authUID)
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
                                self.imageView.image = image
                                self.grayImageView.image = self.convertToGrayScale(image: image!)
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
    
    
    // MARK: TODO need to make it a transaction write
    // for image and data behimnd the image.
    private func uploadSeletedImage(image: UIImage) {
        
        guard let imageData = image.pngData() else {
            return
        }

        let timeStamp = Date().timeIntervalSince1970
        let timeStampString = String(timeStamp) as String
        let regString = ("images/profile_images/" + timeStampString + "file.png") // make it a unique url with the timestamp
        
        let ref = self.storage.child(regString)
        
        ref.putData(imageData, metadata: nil) { _, error in
            guard error == nil else {
                print("Failed to upload.")
                return
            }
            
            ref.downloadURL { url, error in
                guard let url = url, error == nil else {
                    return
                }
                
                
                // ok, the image has been saved to storage correctly.
                // now save the data in the user profile to make searchable
                // perhaps this can be chained together as a 'transaction'
                let urlString = url.absoluteString
                print("Download URL:")
                print(urlString)
                print("Time stamp:")
                print(timeStamp)
                let status = "submitted"
                print("status:")
                print(status)
                
                if let uidString = Auth.auth().currentUser?.uid {
                    
                    // let imageDataRef = self.db.collection("users").document(uidString).collection("profile_images").document()
                    let imageDataRef = self.db.collection("profile_images").document()
                    var selectedType = "headshot"
                    if self.imageTypeSegmentControl.selectedSegmentIndex == 1 {
                        selectedType = "MyActive"
                    }
                    
                    let profileImageData = ProfileImageModel(id: nil,
                                                             timestamp: timeStamp,
                                                             url: urlString,
                                                             status: status,
                                                             uid: uidString,
                                                             type: selectedType,
                                                             userEmail: Auth.auth().currentUser?.email ?? "n/a")
                    
                    
                    do {
                        
                        let _ = try imageDataRef.setData(from: profileImageData)
                    
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
                } else { // couldn't get uid string
                    print("user must be logged in  to upload photo.")
                }
            }
        }
    }
    
    // MARK: TODO Make global function.
    private func convertImageToMaxSqaureCenterImage(sourceImage: UIImage) -> UIImage {
        
        // The shortest side
        let sideLength = min(
            sourceImage.size.width,
            sourceImage.size.height
        )
        
        // Determines the x,y coordinate of a centered
        // sideLength by sideLength square
        let sourceSize = sourceImage.size
        let xOffset = (sourceSize.width - sideLength) / 2.0
        let yOffset = (sourceSize.height - sideLength) / 2.0
        
        // The cropRect is the rect of the image to keep,
        // in this case centered
        let cropRect = CGRect(
            x: xOffset,
            y: yOffset,
            width: sideLength,
            height: sideLength
        ).integral
        
        
        // Center crop the image
        let sourceCGImage = sourceImage.cgImage!
        let croppedCGImage = sourceCGImage.cropping(
            to: cropRect
        )!

        // Use the cropped cgImage to initialize a cropped
        // UIImage with the same image scale and orientation
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: sourceImage.imageRendererFormat.scale,
            orientation: sourceImage.imageOrientation
        )
        
        return croppedImage
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
    
    // MARK: TODO Make global function.
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
