//
//  OpportunityUploadLogModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/30/22.
//

import Foundation
import FirebaseFirestoreSwift
 
struct OpportunityUploadLogModel: Codable {
   
    @DocumentID var id: String?
    let uploadTimestamp: Double?
    let userID: String?
    let userEmail: String?
    let countUploaded: Int?
   
}

