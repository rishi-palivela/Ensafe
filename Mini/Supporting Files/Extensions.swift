//
//  Extensions.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 18/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var tableBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondarySystemBackground
        } else {
            return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
    }
    
    static var mapButtonBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                (traitCollection.userInterfaceStyle == .light) ? .white : .systemGray5
            }
        } else {
            return .white
        }
    }
    
    static var searchBarBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                (traitCollection.userInterfaceStyle == .light) ? .white : .systemGray5
            }
        } else {
            return .white
        }
    }
}

extension Array {
    public subscript(_ indexPath: IndexPath) -> Element {
        self[indexPath.row]
    }
}

extension Array where Element: Collection, Element.Index == Int {
    public subscript(_ indexPath: IndexPath) -> Element.Element {
        self[indexPath.section][indexPath.row]
    }
}

