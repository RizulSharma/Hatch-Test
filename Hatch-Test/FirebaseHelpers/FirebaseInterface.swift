//
//  FirebaseInterface.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 31/03/22.
//

import Foundation
import FirebaseAuth

/// A simple wrapper class for Firebase.
class FirebaseInterface {
    
    static let instance = FirebaseInterface()
    static let LOG_TAG = String(describing: FirebaseInterface.self)
    
    /// Firebase auth.
    private let auth: Auth = Auth.auth()

    
    ///The currently signedIn user object.
    var currentUser: User? {
        get {
            return Auth.auth().currentUser
        }
    }
    
    /// True for UNVERIFIED, BROWSER, and OWNER.
    var isSignedIn: Bool {
        get { return auth.currentUser != nil }
    }
    
    /// True for BROWSER, and OWNER.
    var isVerified: Bool {
        get { return currentUser?.isEmailVerified == true }
    }
    
    private var busyMLD = LiveData<Bool>(initialValue: false)
    /// This bindable(LiveData) is used to show the progressHUD in viewController.
    var busyLD: LiveData<Bool> {
        get {
            busyMLD
        }
    }
    
    func createUser(email: String, password: String, completion: @escaping ((AuthDataResult?, Error?)-> Void) ) {
        self.busyMLD.value = true
        self.auth.createUser(withEmail: email, password: password) { authData, err in
            if let err = err {
                debugPrint("ERROR: \(FirebaseInterface.LOG_TAG) createUser \(err.localizedDescription)")
                self.busyMLD.value = false
                completion(nil, err)
                return
            }
            self.busyMLD.value = false
            debugPrint("SUCCESS: \(FirebaseInterface.LOG_TAG) createUser")
            completion(authData, nil)
        }
    }
    
    func signInWith(email: String, password: String, completion: @escaping ((AuthDataResult?, Error?) -> ())) {
        self.busyMLD.value = true
        self.auth.signIn(withEmail: email, password: password) { (user, err) in
            if let err = err {
                self.logError(funcName: "signInWith", reason: err.localizedDescription)
                completion(nil, err)
                return
            }
            self.logSuccess(funcName: "signInWith")
            completion(user, nil)
        }
    }

    
    fileprivate func logError(funcName: String, reason: String = "") {
        self.busyMLD.value = false
        debugPrint("ERROR: \(FirebaseInterface.LOG_TAG) \(funcName) \(reason)")
    }
    
    fileprivate func logSuccess(funcName: String) {
        self.busyMLD.value = false
        debugPrint("SUCCESS: \(FirebaseInterface.LOG_TAG) \(funcName)")
    }
    
    func signOut() {
        do {
            try self.auth.signOut()
        } catch let err {
            self.logError(funcName: "signOut", reason: err.localizedDescription)
        }
    }
    
    
    
}


class LiveData<T> {
    
    var value: T {
        didSet {
            observer?(value)
        }
    }
    
    var observer: ((T)->())?
    
    func bind(observer: @escaping (T) ->()) {
        self.observer = observer
    }
    
    init(initialValue: T) {
        self.value = initialValue
    }
}
