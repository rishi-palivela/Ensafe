//
//  RoundButton.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 18/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit

class RoundButton: UIButton {

    override func awakeFromNib() {
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        clipsToBounds = true
        imageView?.contentMode = .center
    }

}
