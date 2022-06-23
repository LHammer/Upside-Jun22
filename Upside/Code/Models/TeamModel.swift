//
//  TeamModel.swift
//  Upside
//
//  Created by Hammer, Luke on 6/15/22.
//

import Foundation
import FirebaseFirestoreSwift

struct TeamModel: Codable {
    
    @DocumentID var id: String?
    
    let description: String?
    let ownerEmail: String?
    let ownerUid: String?
    let parentTeam: String?
    let team: String?
    
}


