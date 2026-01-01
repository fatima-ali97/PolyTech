//
//  UIView+CardStyle.swift
//  PolyTech
//
//  Created by BP-19-130-05 on 15/12/2025.
//

import Foundation
import UIKit

extension UIView {
    
    func applyCardStyle(
        cornerRadius: CGFloat = 12,
        shadowColor: UIColor = .black,
        shadowOpacity: Float = 0.08,
        shadowOffset: CGSize = CGSize(width: 0, height: 6),
        shadowRadius: CGFloat = 12
    ) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        
        backgroundColor = .systemBackground
    }
}

extension UIColor {
    static let statusCompleted  = UIColor(red: 116/255, green: 146/255, blue: 188/255, alpha: 1) // #7492BC
    static let statusInProgress = UIColor(red:  56/255, green:  95/255, blue: 189/255, alpha: 1) // #385FBD
    static let statusPending    = UIColor(red: 119/255, green: 127/255, blue: 141/255, alpha: 1) // #777F8D
}
