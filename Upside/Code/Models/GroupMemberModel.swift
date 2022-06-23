//
//  GroupMemberModel.swift
//  Upside
//
//  Created by Hammer, Luke on 6/17/22.
//

import Foundation
import FirebaseFirestoreSwift

struct GroupMemberModel: Codable {
    
    @DocumentID var id: String?
    
    let firebaseUid: String?
    let products: [String]?
    let startTimeStamp: Double?
    let endTimeStamp: Double?
    let teamUid: String?
    let userEmail: String?
    
}

