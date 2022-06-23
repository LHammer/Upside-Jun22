//
//  ProfileImageModel.swift
//  Upside
//
//  Created by Hammer, Luke on 5/17/22.
//

import Foundation
import FirebaseFirestoreSwift

struct ProfileImageModel: Codable {
    
    @DocumentID var id: String?
    
    let timestamp: Double?
    let url: String?
    let status: String?
    let uid: String?
    let type: String?
    let userEmail: String?
    
}
