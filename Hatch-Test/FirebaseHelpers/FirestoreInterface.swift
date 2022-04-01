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
import FirebaseDatabase

/// Handles Db operations with Firebase Realtime Database.
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
    
    /// ref to realtime DB.
    var ref: DatabaseReference! {
        get {
            Database.database(url: "https://hatch-test-58d37-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        }
    }
    
    /// Current logged in user.
    private var user: User? {
        get {
             return FirebaseInterface.instance.currentUser
        }
    }
    
    
    /// This bindable(LiveData) is used to show the progressHUD in viewController.
    private var busyMLD = LiveData<Bool>(initialValue: false)
    var busyLD: LiveData<Bool> {
        get {
            busyMLD
        }
    }
    
    /// This func saves the world map data to the firebase realtime DB.
    /// - Parameters:
    ///   - mapData: The base64 encoded string. (We use string because realtimeDB only supports NSString NSNumber NSDictionary NSArray dataTypes.)
    ///   - completion: returns true is save was successful.
    func writeMapToRDB(mapData: String, completion: @escaping (Bool, Error?)-> ()) {
        self.busyMLD.value = true
        self.busyMLD.value = true
        let mapData: [String: Any] = ["mapData": mapData]
        self.ref.child("users").child(user?.uid ?? "?").setValue(mapData) { err, ref in
            if let err = err {
                self.logError(funcName: "writeMapToRDB", reason: err.localizedDescription)
                completion(false, err)
                return
            }
            self.logSuccess(funcName: "writeMapToDB")
            completion(true, nil)
        }
        
    }
    
    /// This func reads the encded string save on Firebase RelatimeDB.
    /// - Parameter completion: returns the encoded string converted to aworld map.
    func readMapFromRDB(completion: @escaping (ARWorldMap?)-> ()) {
        self.busyMLD.value = true
        ref.child("users/\(user?.uid ?? "?")/mapData").getData(completion:  { err, snapshot in
            if let err = err {
                self.logError(funcName: "readMapFromDB", reason: err.localizedDescription)
                completion(nil)
                return
            }
            if let mapDataStr = snapshot.value as? String {
                if let arData = Data(base64Encoded: mapDataStr) {
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
                    self.logError(funcName: "readMapFromDB", reason: "Unable to convert to data.")
                    completion(nil)
                }
            } else {
                self.logError(funcName: "readMapFromDB", reason: "Unable to find mapData.")
                completion(nil)
            }
        })
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
