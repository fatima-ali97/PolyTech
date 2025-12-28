//
//  DonutChartView.swift
//  PolyTech
//
//  Created by BP-19-130-05 on 15/12/2025.
//

import UIKit

class DonutChartView: UIView {
    
    struct Segment {
        let value: CGFloat
        let color: UIColor
    }
    
    var segments: [Segment] = [] {
        didSet { setNeedsLayout() }
    }
    
    private let ringLayer = CAShapeLayer()
    private var segmentLayers: [CAShapeLayer] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        layer.addSublayer(ringLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawChart()
    }
    
    private func drawChart() {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()
        
        let total = segments.reduce(0) { $0 + $1.value }
        guard total > 0 else { return }
        
        let lineWidth: CGFloat = max(10, min(bounds.width, bounds.height) * 0.18)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        
        let startAngle: CGFloat = -.pi / 2
        
        for seg in segments {
            let endAngle = startAngle + (2 * .pi) * (seg.value / total)
            
            let path = UIBezierPath(
                arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = seg.color.cgColor
            layer.lineWidth = lineWidth
            layer.lineCap = .butt
            
            self.layer.addSublayer(layer)
            segmentLayers.append(layer)
        }
        
        let hole = UIBezierPath(
            arcCenter: center, radius: radius - lineWidth / 2, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        ringLayer.path = hole.cgPath
        ringLayer.fillColor = UIColor.systemBackground.cgColor
        ringLayer.strokeColor = UIColor.clear.cgColor
        
        
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
