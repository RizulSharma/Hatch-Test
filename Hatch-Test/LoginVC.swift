//
//  LoginVC.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 31/03/22.
//

import UIKit
import LBTATools
import JGProgressHUD

class LoginVC: UIViewController {
    
    private let titleLabel = UILabel(text: "Hatch-Test", font: .systemFont(ofSize: 30, weight: .bold), textColor: .darkGray, textAlignment: .center)
    private let emailTextField = UITextField(placeholder: " Enter you email")
    private let passwordTxtField = UITextField(placeholder: " Enter your password")
    private let signInButton = UIButton(title: "SIGN IN", titleColor: .darkGray, font: .systemFont(ofSize: 14, weight: .semibold), backgroundColor: UIColor.cyan)
    private let registerButton = UIButton(title: "REGISTER", titleColor: .darkGray, font: .systemFont(ofSize: 14, weight: .semibold), backgroundColor: UIColor.cyan)
    
    ///Progress heads up display used for showing network processing.
    fileprivate let progressHUD = JGProgressHUD(style: .dark)
    
    private var email: String {
        return emailTextField.text!
    }
    
    private var password: String {
        return passwordTxtField.text!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupLayout()
        self.setupActions()
        self.setupTapGesture()
        self.setupBindables()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseInterface.instance.signOut()
    }
    
    fileprivate func setupLayout() {
        self.view.backgroundColor = .white
        self.view.stack(UIView().withHeight(50),
                        titleLabel,
                        UIView().withHeight(50),
                        emailTextField.withHeight(40),
                        passwordTxtField.withHeight(40), UIView(),
                        UIView().hstack(signInButton,
                                        registerButton, spacing: 4, distribution: .fillEqually).withHeight(40),
                        UIView().withHeight(10),
                        spacing: 10).withMargins(.allSides(20))
        
        [emailTextField, passwordTxtField].forEach { field in
            field.layer.borderWidth = 1
            field.layer.borderColor = UIColor.darkGray.cgColor
            field.layer.cornerRadius = 5
        }
        
        [signInButton, registerButton].forEach { bttn in
            bttn.layer.cornerRadius = 5
        }
    }
    
    fileprivate func setupActions() {
        self.signInButton.addTarget(self, action: #selector(self.performSignIn), for: .touchUpInside)
        self.registerButton.addTarget(self, action: #selector(self.performRegistration), for: .touchUpInside)

    }
    
    /// Sign in a user. It does not matter if the account email address is verified or not.
    /// As long as the credentials are correct we can sign them in.
    @objc fileprivate func performSignIn() {


        FirebaseInterface.instance.signInWith(email: self.email, password: self.password) { data,   err in
            if let err = err {
                CustomToast.show(message: "Sign in failed: \(err.localizedDescription)", controller: self)
                return
            }
            //FIXME: SHOW ALERT AND CONTINUE.
            CustomToast.show(message: "Sign in successfull", controller: self)
            self.showAlert(title: "HATCH-TEST", message: "Registered successfully.") { _ in
                self.performSegue(withIdentifier: "goToAr", sender: self)
            }
        }
    }
    
    /// Register a new user account.
    @objc fileprivate func performRegistration() {
        debugPrint("performRegistration pressed")
        self.performSegue(withIdentifier: "goToAr", sender: self)

//        FirebaseInterface.instance.createUser(email: self.email, password: self.password) { data, err in
//            if let err = err {
//                CustomToast.show(message: "Registration failed: \(err.localizedDescription)", controller: self)
//                return
//            }
//            //FIXME: SHOW ALERT AND CONTINUE.
//            CustomToast.show(message: "SUCCESS: registering user", controller: self)
//            self.showAlert(title: "HATCH-TEST", message: "Registered successfully.") { _ in
//                self.performSegue(withIdentifier: "goToAr", sender: self)
//            }
//        }
        
    }

    fileprivate func setupTapGesture() {
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
    
    @objc fileprivate func handleTapDismiss() {
        self.view.endEditing(true) // dismisses keyboard
    }
    
    fileprivate func setupBindables() {
        self.progressHUD.textLabel.text = "Please wait.."
        FirebaseInterface.instance.busyLD.bind { isBusy in
            if isBusy {
                self.view.endEditing(true)
                self.progressHUD.show(in: self.view)
            } else {
                self.progressHUD.dismiss(animated: true)
            }
        }
        
//        FirestoreInterface.instance.busyLD.bind { isBusy in
//            if isBusy {
//                self.view.endEditing(true)
//                self.progressHUD.show(in: self.view)
//            } else {
//                self.progressHUD.dismiss(animated: true)
//            }
//        }
    }
}
