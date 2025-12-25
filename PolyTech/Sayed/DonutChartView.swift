//
//  DonutChartView.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 21/12/2025.
//

import UIKit

class DonutChartView: UIView {
    
    var dataEntries: [(value: CGFloat, color: UIColor)] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let total = dataEntries.reduce(0) { $0 + $1.value }
        guard total > 0 else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 20
        let lineWidth: CGFloat = 35
        
        var startAngle: CGFloat = -CGFloat.pi / 2
        
        for entry in dataEntries {
            let endAngle = startAngle + (entry.value / total) * (CGFloat.pi * 2)
            
            let path = UIBezierPath(arcCenter: center,
                                   radius: radius,
                                   startAngle: startAngle,
                                   endAngle: endAngle,
                                   clockwise: true)
            
            entry.color.setStroke()
            path.lineWidth = lineWidth
            path.lineCapStyle = .butt
            path.stroke()
            
            startAngle = endAngle
        }
    }
}
