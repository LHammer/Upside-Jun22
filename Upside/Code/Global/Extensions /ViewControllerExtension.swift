//
//  ViewControllerExtension.swift
//  Upside
//
//  Created by Luke Hammer on 4/29/22.
//

import UIKit

var vSpinner : UIView?

// MARK: TODO need to move to it's own file.
// MARK: Formatter
extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}

// MARK: TODO need to move to it's own file.
extension Numeric {
    var formattedWithSeparator: String { Formatter.withSeparator.string(for: self) ?? "" }
}


extension UIViewController {
    
    func setupBackButton() {
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backPressed(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    
    @objc func backPressed(sender: UIButton) {
        self.performSegueToReturnBack()
    }

    func setupDefualtNavigationBar() {
        
        overrideUserInterfaceStyle = .dark
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.barTintColor = .black
        nav?.tintColor = .white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        nav?.isTranslucent = false
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 15))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "a_logo")
        imageView.image = image
        navigationItem.titleView = imageView
        
        print(imageView)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func performSegueToReturnBack()  {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    func showSpinner(onView : UIView) {
        
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
    /*
    var vSpinner : UIView?
    extension UIViewController {
        func showSpinner(onView : UIView) {
            let spinnerView = UIView.init(frame: onView.bounds)
            spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            let ai = UIActivityIndicatorView.init(style: .whiteLarge)
            ai.startAnimating()
            ai.center = spinnerView.center
            
            DispatchQueue.main.async {
                spinnerView.addSubview(ai)
                onView.addSubview(spinnerView)
            }
            
            vSpinner = spinnerView
        }
        
        func removeSpinner() {
            DispatchQueue.main.async {
                vSpinner?.removeFromSuperview()
                vSpinner = nil
            }
        }
    }
    
    */
    
    
    
}
