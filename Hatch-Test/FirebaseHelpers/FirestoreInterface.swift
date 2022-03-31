//
//  FirestoreInterface.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 31/03/22.
//

import FirebaseFirestore
import FirebaseAuth
import UIKit
import ARKit

class FirestoreInterface: NSObject {
    
    static let instance = FirestoreInterface()
    static let LOG_TAG = String(describing: FirestoreInterface.self)
    
    private var USERS: String {
        #if DEBUG
        return "testUsers"
        #else
        return "users"
        #endif
    }
    
    private var userPath: DocumentReference {
        get {
            /// Access the Cloud Firestore instance
            let db = Firestore.firestore()
            return db.collection(USERS).document(FirebaseInterface.instance.currentUser?.uid ?? "?")
        }
    }
    
    private var busyMLD = LiveData<Bool>(initialValue: false)
    /// This bindable(LiveData) is used to show the progressHUD in viewController.
    var busyLD: LiveData<Bool> {
        get {
            busyMLD
        }
    }
    
    func writeMapToDB(mapData: Any, completion: @escaping (Bool, Error?)-> ()) {
        self.busyMLD.value = true
        let mapData: [String: Any] = ["mapData": mapData]
        userPath.setData(mapData, merge: false) { err in
            if let err = err {
                self.logError(funcName: "writeMapToDB", reason: err.localizedDescription)
                completion(false, err)
                return
            }
            self.logSuccess(funcName: "writeMapToDB")
            completion(true, nil)
        }
    }
    
    
    func readMapFromDB(completion: @escaping (ARWorldMap?)-> ()) {
        self.busyMLD.value = true
        userPath.getDocument { snapshot, err in
            if let err = err {
                self.logError(funcName: "readMapFromDB", reason: err.localizedDescription)
                return
            }
            if let snapshot = snapshot {
                let data = snapshot.data()
                if let arData = data?["mapData"] as? Data {
                    let decoder = JSONDecoder()
                    do {
                        let decoded = try decoder.decode(ARData.self, from: arData)
                        debugPrint("DECODED, \(decoded)")
                        if let map = decoded.worldMap {
                            self.logSuccess(funcName: "readMapFromDB")
                            completion(map)
                        }
                    } catch {
                        self.logError(funcName: "readMapFromDB", reason: error.localizedDescription)
                        completion(nil)
                    }
                } else {
                    self.logError(funcName: "readMapFromDB", reason: "Data not found.")
                    completion(nil)
                }
            } else {
                self.logError(funcName: "readMapFromDB", reason: "Snapshot not found.")
                completion(nil)
            }
        }
    }
    
    
    fileprivate func logError(funcName: String, reason: String = "") {
        self.busyMLD.value = false
        debugPrint("ERROR: \(FirestoreInterface.LOG_TAG) \(funcName) \(reason)")
    }
    
    fileprivate func logSuccess(funcName: String) {
        self.busyMLD.value = false
        debugPrint("SUCCESS: \(FirestoreInterface.LOG_TAG) \(funcName)")
    }
}
