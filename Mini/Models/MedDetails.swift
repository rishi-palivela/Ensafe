//
//  MedicalHistory.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 20/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import Foundation

struct MedDetails: Codable {
    
    enum BloodGroup: Int {
        case aPos
        case aNeg
        case bPos
        case bNeg
        case oPos
        case oNeg
        case abPos
        case abNeg
        case others
    }
    
    enum Comorbidity: Int {
        case diabities
        case hypertension
        case hypothyroid
        case asthama
    }
    
    enum CodingKeys: String, CodingKey {
        case age
        case weight
        case bloodGroup
        case comorbidities
    }
    
    var age: Int
    var weight: Int
    var bloodGroup: BloodGroup
    var comorbidities: [Comorbidity]
    
    init(_ age: Int, _ weight: Int, _ bloodGroup: BloodGroup, _ comorbidities: [Comorbidity]) {
        self.age = age
        self.weight = weight
        self.bloodGroup = bloodGroup
        self.comorbidities = comorbidities
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.age = try container.decode(Int.self, forKey: .age)
        self.weight = try container.decode(Int.self, forKey: .weight)
        
        let bloodGroup = try container.decode(Int.self, forKey: .bloodGroup)
        self.bloodGroup = BloodGroup(rawValue: bloodGroup)!
        
        let comorbidities = try container.decode([Int].self, forKey: .comorbidities)
        self.comorbidities = comorbidities.map { Comorbidity(rawValue: $0)! }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(age, forKey: .age)
        try container.encode(weight, forKey: .weight)
        try container.encode(bloodGroup.rawValue, forKey: .bloodGroup)
        try container.encode(comorbidities.map { $0.rawValue } , forKey: .comorbidities)
    }
    
}
