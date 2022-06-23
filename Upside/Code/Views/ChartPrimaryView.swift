//
//  ChartPrimaryView.swift
//  Upside
//
//  Created by Luke Hammer on 6/7/22.
//


// MARK: Currently just simple line graph. Need to make all sorts of graphs.
import UIKit

class ChartPrimaryView: UIView {
    
    var lineGraphLayer: CAShapeLayer?
    var gridLineLayer: CAShapeLayer?
    
    
    // MARK: Make this an array to handle mult
//    var chartModel: StandardChartModel? {
//        didSet {
//            lineGraphLayer.frame = bounds
//        }
//    }
    
    var newChartModels: [StandardChartModel]?
    var renameUserCallSummaryHistoryModel: UserCallSummaryHistoryModel?
    var renameTeamCallSummaryHistoryModel: TeamCallSummaryHistoryModel?
    
//    override func layoutSubviews() {
//        layoutAllSubLayers()
//    }
//    
//    override func safeAreaInsetsDidChange() {
//        layoutAllSubLayers()
//    }
    
    func layoutAllSubLayers() {
        
        
        if self.lineGraphLayer != nil && self.lineGraphLayer?.sublayers != nil {
            for layer in self.lineGraphLayer!.sublayers! {
                layer.frame = self.bounds
                layer.setNeedsLayout()
                layer.setNeedsDisplay()
            }
        }
        
        
        
        
        if self.gridLineLayer != nil && self.gridLineLayer?.sublayers != nil {
            for layer in self.gridLineLayer!.sublayers! {
                layer.frame = self.bounds
                layer.setNeedsLayout()
                layer.setNeedsDisplay()
            }
        }
        
        self.lineGraphLayer?.frame = self.bounds
        self.lineGraphLayer?.setNeedsLayout()
        self.lineGraphLayer?.setNeedsDisplay()
        
        self.gridLineLayer?.frame = self.bounds
        self.gridLineLayer?.setNeedsLayout()
        self.gridLineLayer?.setNeedsDisplay()
        
    }
    
//    override func layoutSubviews() {
//        self.resetDrawing()
//    }
    
//    public func resetDrawing() {
//
//        if layer.sublayers != nil {
//            for layer in self.layer.sublayers! {
//                layer.frame = bounds
//            }
//        }
//
//        self.setNeedsLayout()
//        self.setNeedsDisplay()
//    }
    
    // MARK: TODO need to move to generic model
    private func drawGridLayer(summaryHistoryModel: TeamCallSummaryHistoryModel?) {
        
        if self.gridLineLayer?.sublayers != nil {
            for l in self.layer.sublayers! {
                l.removeFromSuperlayer()
            }
            
            gridLineLayer = nil
        }
        
        if self.gridLineLayer == nil {
            self.gridLineLayer = CAShapeLayer()
            self.layer.addSublayer(gridLineLayer!)
        }
        
        if summaryHistoryModel != nil {
            if let gridShapeLayer = self.getGridShapeLayer(summaryHistoryModel: summaryHistoryModel!) {
                self.gridLineLayer!.addSublayer(gridShapeLayer)
            }
        }
    }
    
    
    // MARK: TODO need to move to generic model
    private func drawGridLayer(summaryHistoryModel: UserCallSummaryHistoryModel?) {
        
        if self.gridLineLayer?.sublayers != nil {
            for l in self.layer.sublayers! {
                l.removeFromSuperlayer()
            }
            
            gridLineLayer = nil
        }
        
        if self.gridLineLayer == nil {
            self.gridLineLayer = CAShapeLayer()
            self.layer.addSublayer(gridLineLayer!)
        }
        
        if summaryHistoryModel != nil {
            if let gridShapeLayer = self.getGridShapeLayer(summaryHistoryModel: summaryHistoryModel!) {
                self.gridLineLayer!.addSublayer(gridShapeLayer)
            }
        }
    }
    
    
    private func drawLineGraphLayer(chartModels: [StandardChartModel]?) {
        
        if self.lineGraphLayer?.sublayers != nil {
            for l in self.layer.sublayers! {
                l.removeFromSuperlayer()
            }
            
            lineGraphLayer = nil
        }
        
        
        
        if self.lineGraphLayer == nil {
            self.lineGraphLayer = CAShapeLayer()
            self.layer.addSublayer(lineGraphLayer!)
        }
        
        

        if chartModels != nil && chartModels!.count > 0 {
            
            
            for cm in chartModels! {
                let layer = self.getBasicLineGraphLayer(aChartModel: cm)
                // self.layer.addSublayer(layer)
                layer.frame = bounds
                self.lineGraphLayer!.addSublayer(layer)
            }
        }
    }
    
    // make x0, y0 (0, 0)
    private func normalizePoint(pt: CGPoint) -> CGPoint {
        
        /*return CGPoint(x: pt.x,
                       y: self.frame.size.height - pt.y)*/
        
        return CGPoint(x: pt.x,
                       y: self.bounds.size.height - pt.y)
        
    }
    
    // MARK: TODO come up with generic class for charts rather than 'summaryHistoryModel'
    // or just the Int values, idiot.
    // starting with basic method, handling only outer edges included and just horizontal lines.
    private func getGridShapeLayer(summaryHistoryModel: TeamCallSummaryHistoryModel) -> CAShapeLayer? {
        
        if let path = self.getHorizontalGridLinesFor(aFrame: self.frame,
                                                     count: summaryHistoryModel.gridHorizontalCount) {
            
            let layer = CAShapeLayer()
            
            let color = UIColor(red: 240.0 / 255.0,
                                green: 240.0 / 255.0,
                                blue: 240.0 / 255.0,
                                alpha: 1.0)
            layer.strokeColor = color.cgColor
            // layer.lineWidth = 0.0 // lineWidth // 1.5
            layer.fillColor = UIColor.clear.cgColor
            path.lineWidth = 0.25
            path.lineCapStyle = .round
            layer.lineCap = .round
            //path.close()
            path.stroke()
            
            return layer
            
        }
        
        return nil
    }
    
    // MARK: TODO come up with generic class for charts rather than 'summaryHistoryModel'
    // or just the Int values, idiot.
    // starting with basic method, handling only outer edges included and just horizontal lines.
    private func getGridShapeLayer(summaryHistoryModel: UserCallSummaryHistoryModel) -> CAShapeLayer? {
        
        if let path = self.getHorizontalGridLinesFor(aFrame: self.frame,
                                                     count: summaryHistoryModel.gridHorizontalCount) {
            
            let layer = CAShapeLayer()
            
            let color = UIColor(red: 240.0 / 255.0,
                                green: 240.0 / 255.0,
                                blue: 240.0 / 255.0,
                                alpha: 1.0)
            layer.strokeColor = color.cgColor
            // layer.lineWidth = 0.0 // lineWidth // 1.5
            layer.fillColor = UIColor.clear.cgColor
            path.lineWidth = 0.25
            path.lineCapStyle = .round
            layer.lineCap = .round
            //path.close()
            path.stroke()
            
            return layer
            
        }
        
        return nil
    }
    
    
    // basic, assuming each outer side is included in count
    private func getHorizontalGridLinesFor(aFrame: CGRect, count: Int) -> UIBezierPath? {
        
        if count < 2 { // need at least the outer lines for now i.e 2
            return nil
        }
        
        let frameHeight = aFrame.height
        let incrementHeight = frameHeight / (Double(count) - 1.0)
        
        var path: UIBezierPath!
        path = UIBezierPath()
        
    
        // iterate from i = 1 to 1 = 3
        for i in 0...count-1 {
            
            let leftPt = CGPoint(x: 0.0,
                                 y: incrementHeight * Double(i))
            let rightPt = CGPoint(x: aFrame.width,
                                  y: incrementHeight * Double(i))
            
            path.move(to: leftPt)
            path.addLine(to: rightPt)
        }
        
        return path
    }
    
    

    
    // MARK: New method with pass in so multiple paths can be made.
    // private func getBasicLineGraphPath(aChartModel: StandardChartModel) -> UIBezierPath? {
    private func getBasicLineGraphLayer(aChartModel: StandardChartModel) -> CAShapeLayer {

        
        var path: UIBezierPath!
        path = UIBezierPath()

        let dateDoubles = aChartModel.chartData.first!.value.keys.sorted()
        let amountRange = aChartModel.verticalRange.max -  aChartModel.verticalRange.min
        let dateRange = aChartModel.horizontalRange.max -  aChartModel.horizontalRange.min
        
//        let w = Double(frame.size.width)
//        let h = Double(frame.size.height)
        
        let w = Double(bounds.size.width)
        let h = Double(bounds.size.height)

        
        var pts = [CGPoint]()

        for date in dateDoubles {
            let x = CGFloat( ((date - aChartModel.horizontalRange.min) / dateRange) * w )
            let amount = aChartModel.chartData.first!.value[date]
            let y = CGFloat( ((amount! - aChartModel.verticalRange.min) / amountRange) * h )
            pts.append(normalizePoint(pt:CGPoint(x: x,
                                                 y: y)))
        }

        for (index, pt) in pts.enumerated() {
            if index == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        
        let lineLayer = CAShapeLayer()
        
        
        
        let lineColor = UIColor(red: aChartModel.lineRed,
                                green: aChartModel.lineGreen,
                                blue: aChartModel.lineBlue,
                                alpha: aChartModel.lineAlpha)
        
        
        
        lineLayer.strokeColor = lineColor.cgColor // ui_active_blue.cgColor
        lineLayer.lineWidth = aChartModel.lineWidth // lineWidth // 1.5
        lineLayer.fillColor = UIColor.clear.cgColor
        
        path.lineCapStyle = .round
        lineLayer.lineCap = .round
        //path.close()
        path.stroke()
        
        //var lineCapStyle: CGLineCap

        
        lineLayer.path = path.cgPath
        return lineLayer
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        // MARK: TODO need two until we get a common class
        self.drawGridLayer(summaryHistoryModel: self.renameUserCallSummaryHistoryModel)
        self.drawGridLayer(summaryHistoryModel: self.renameTeamCallSummaryHistoryModel)
        
        self.drawLineGraphLayer(chartModels: self.newChartModels)
        
        
        //drawGridLayer
        //drawLineGraphLayer
    }
}
