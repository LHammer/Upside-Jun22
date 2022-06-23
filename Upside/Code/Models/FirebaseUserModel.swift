//
//  FirebaseUserModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/1/22.
//

import Foundation
import FirebaseFirestoreSwift

struct FirebaseUserModel: Codable {
    
    @DocumentID var id: String?
    
    
    let department: String?
    let displayRole: String?
    let email: String?
    let firebaseUid: String?
    let firstName: String?
    let fullName: String?
    // let id: String?
    let lastName: String?
    let role: String?
    let timeZoneID: String?
    let teamOwned: String?
    let teamOwnedUid: String?
    
    
    
    /*
    var firebaseUID: String?
    var department: String?
    var displayRole: String?
    var role: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var fullName: String?
    var team: String?
    var timeZoneID: String?
     */

}


/*
 
 struct Datum: Codable {
     
     let department: String?,
     let displayRole: String?,
     let email: String?,
     let firebaseUid: String?,
     let firstName: String?,
     let fullName: String?,
     let id: String?,
     let lastName: String?,
     let role: String?,
     let timeZoneID: String?,
     let teamOwned: String?,
     let teamOwnedUid: String?
     
 }
  
 
 */
