//
//  FirebaseUser.swift
//  Upside
//
//  Created by Luke Hammer on 4/30/22.
//

import Foundation
import FirebaseFirestoreSwift

struct FirebaseUser: Codable {
    
    @DocumentID var id: String?
    
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

}

