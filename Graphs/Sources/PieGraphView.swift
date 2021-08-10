//
//  PieGraphView.swift
//  Graphs
//
//  Created by HiraiKokoro on 2016/06/07.
//  Copyright © 2016年 Recruit Holdings Co., Ltd. All rights reserved.
//

import UIKit

public struct PieGraphViewConfig {
    
    public var pieColors: [UIColor]?
    public var textColor: UIColor
    public var textFont: UIFont
    public var contentInsets: UIEdgeInsets
    public var donutRadiusRatio: CGFloat
    public var fractionsIndentInRadians: Double
    
    public init(
        pieColors: [UIColor]? = nil,
        textColor: UIColor? = nil,
        textFont: UIFont? = nil,
        donutRadiusRatio: CGFloat = 0.0,
        fractionsIndentInRadians: Double = 0,
        contentInsets: UIEdgeInsets? = nil
    ) {
        self.pieColors = pieColors
        self.textColor = textColor ?? DefaultColorType.PieText.color()
        self.textFont = textFont ?? UIFont.systemFont(ofSize: 10.0)
        self.donutRadiusRatio = ((donutRadiusRatio < 0) || (donutRadiusRatio > 1)) ? 0 : donutRadiusRatio
        self.fractionsIndentInRadians = fractionsIndentInRadians
        self.contentInsets = contentInsets ?? .zero
    }
    
}

internal class PieGraphView<T: Hashable, U: NumericType>: UIView {
    
    private var graph: PieGraph<T, U>? {
        didSet {
            self.config.pieColors = DefaultColorType.pieColors(graph?.units.count ?? 0)
            self.setNeedsDisplay()
        }
    }
    private var config: PieGraphViewConfig
    
    init(frame: CGRect, graph: PieGraph<T, U>?) {
        
        self.config = PieGraphViewConfig(pieColors: DefaultColorType.pieColors(graph?.units.count ?? 0))
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.graph = graph
    }
    
    required init?(coder: NSCoder) {
        print("init(coder:) has not been implemented")
        return nil
    }
    
    func setPieGraphViewConfig(_ config: PieGraphViewConfig?) {
        self.config = config ?? PieGraphViewConfig()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let graph = self.graph else { return }
        
        func convert<S: NumericType>(s: S, arr: [S], f: (S) -> S) -> [S] {
            switch arr.match {
            case let .some((h, t)):
                let buf = [f(h) + s]
                return buf + convert(s: h + s, arr:t, f: f)
            case .none: return []
            }
        }
        
        let colors = self.config.pieColors ?? DefaultColorType.pieColors(graph.units.count)
        
        let values = graph.units.map({ max($0.value, U(0)) })
        let total = values.reduce(U(0), { $0 + $1 })
        let percentages = values.map({ Double($0.floatValue() / total.floatValue()) })
        
        let rect = self.graphFrame()
        
        let context = UIGraphicsGetCurrentContext();
        let x = rect.size.width / 2.0 + rect.origin.x
        let y = rect.size.height / 2.0 + rect.origin.y
        let radius = min(rect.width, rect.height) / 2.0
        
        let centers = convert(s: 0.0, arr: percentages) { $0 / 2.0 }.map { (c) -> CGPoint in
            let angle = Double.pi * 2.0 * c - Double.pi / 2.0
            return CGPoint(
                x: Double(x) + cos(angle) * Double(radius * 3.0 / 4.0),
                y: Double(y) + sin(angle) * Double(radius * 3.0 / 4.0)
            )
        }
        
        var startAngle = -Double.pi / 2.0

        percentages.enumerated().forEach { (index, f) in
            let endAngle = startAngle + Double.pi * 2.0 * f - config.fractionsIndentInRadians
            context?.move(to: CGPoint(x: x, y: y))
            context?.addArc(center: CGPoint(x: x, y: y),
                            radius: radius,
                            startAngle: CGFloat(startAngle + config.fractionsIndentInRadians),
                            endAngle: CGFloat(endAngle),
                            clockwise: false)

            if config.donutRadiusRatio != 0 {
                context?.addArc(center: CGPoint(x: x, y: y),
                                radius: radius * (1 - config.donutRadiusRatio),
                                startAngle: CGFloat(endAngle),
                                endAngle: CGFloat(startAngle + config.fractionsIndentInRadians),
                                clockwise: true)
            }
            
            context?.setFillColor(colors[index].cgColor)
            context?.closePath()
            context?.fillPath()
            startAngle = endAngle + config.fractionsIndentInRadians
        }
        
        zip(graph.units, centers).forEach { (u, center) in
            
            guard let str = self.graph?.textDisplayHandler?(u, total) else {
                return
            }
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            
            let attrStr = NSAttributedString(string: str, attributes: [
                NSAttributedString.Key.foregroundColor:self.config.textColor,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0),
                NSAttributedString.Key.paragraphStyle: paragraph
            ])
            
            let size = attrStr.size()
            
            attrStr.draw(
                in: CGRect(
                    origin: CGPoint(
                        x: center.x - size.width / 2.0,
                        y: center.y - size.height / 2.0
                    ),
                    size: size
                )
            )
        }
    }
    
    private func graphFrame() -> CGRect {
        return CGRect(
            x: self.config.contentInsets.left,
            y: self.config.contentInsets.top,
            width: self.frame.size.width - self.config.contentInsets.horizontalMarginsTotal(),
            height: self.frame.size.height - self.config.contentInsets.verticalMarginsTotal()
        )
    }

}
