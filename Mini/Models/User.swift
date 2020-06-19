//
//  User.swift
//  Mini
//
//  Created by Rishi Palivela on 20/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import Foundation

struct EnsafeUser: Codable {
    
    enum Gender: Int {
        case male
        case female
        case other
        case notDetermined = -1
    }
    
    enum Kind: Int {
        case citizen
        case police
        case ambulance
        case firestation
        case other
        case notDetermined = -1
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case age
        case gender
        case kind
    }
    
    var id: String?
    var name: String
    var email: String
    var age: Int
    var gender: Gender
    var kind: Kind
    
    init(name: String, email: String, age: Int, gender: Gender,kind: Kind) {
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.kind = kind
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        age = try container.decode(Int.self, forKey: .age)
        gender = Gender(rawValue: (try? container.decode(Int.self, forKey: .gender)) ?? -1)!
        kind = Kind(rawValue: (try? container.decode(Int.self, forKey: .kind)) ?? -1)!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(age, forKey: .age)
        try container.encode(gender.rawValue, forKey: .gender)
        try container.encode(kind.rawValue, forKey: .kind)
    }
    
}
