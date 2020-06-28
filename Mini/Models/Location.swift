//
//  Location.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 26/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

class Location: Codable {
    
    enum CodingKeys: String, CodingKey {
        case time
        case latitude
        case longitude
    }
    
    private(set) var time: Date
    private(set) var latitide: Double
    private(set) var longitude: Double
    
//    var geoPoint: GeoPoint {
//        get {
//            GeoPoint(latitude: latitide, longitude: longitude)
//        }
//        set {
//            self.latitide = newValue.latitude
//            self.longitude = newValue.latitude
//        }
//    }
    
    init(_ latitide: Double, _ longitude: Double, at time: Date = Date()) {
        self.latitide = latitide
        self.longitude = longitude
        self.time = time
    }
    
    init(from location: CLLocation, at time: Date = Date()) {
        self.latitide = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.time = time
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        latitide = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        time =  Date(timeIntervalSince1970: try container.decode(Double.self, forKey: .time))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(latitide, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(time.timeIntervalSince1970, forKey: .time)
    }
    
    static func store(location: Location, in locRef: CollectionReference?, withCompletion completionHandler: ((Error?) -> Void)? = nil) {
        guard let doc = locRef?.document(),
            let data = try? JSONEncoder().encode(location),
            let dataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        doc.setData(dataDict) { error in
            completionHandler?(error)
        }
    }
    
}
