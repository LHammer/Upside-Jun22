//
//  UserRequestModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/1/22.
//

import Foundation
import FirebaseFirestoreSwift

struct UserRequestModel: Codable {
    
    @DocumentID var id: String?
    
    let email: String?
    let firstName: String?
    let lastName: String?
    let role: String?
    let timestamp: Double?
    let deviceUID: String?
    let status: String?
    let firebaseUID: String?
}
