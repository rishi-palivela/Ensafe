//
//  Route.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 20/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import Foundation
import MapKit

class Route {
    
    enum Preference: String {
        case first
        case second
        case last
    }
    
    static var preferenceColors: [Preference: UIColor] = [.first: .systemBlue,
                                                          .second: UIColor(white: 0.9, alpha: 1),
                                                          .last: .lightGray]
    
}
