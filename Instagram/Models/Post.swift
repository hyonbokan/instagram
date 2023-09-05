//
//  Post.swift
//  Instagram
//
//  Created by dnlab on 2023/09/05.
//

import Foundation

struct Post: Codable {
    let id: String
    let caption: String
    let postedDate: String
    var likers: [String]
    
    var storageReference: String? {
        guard let username = UserDefaults.standard.string(forKey: "username") else { return nil }
        return "\(username)/posts/\(id).png"
    }
}
