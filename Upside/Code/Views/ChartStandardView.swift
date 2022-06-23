//
//  ChartStandardView.swift
//  Upside
//
//  Created by Luke Hammer on 6/7/22.
//

import UIKit

class ChartStandardView: UIView {
    
    @IBOutlet weak var topHeadingLabel: UILabel!
    var topHeading: String? {
        didSet {
            if topHeading == nil {
                self.topHeadingLabel.text = ""
            } else {
                self.topHeadingLabel.text = topHeading!
            }
        }
    }
    
    @IBOutlet weak var displayView: ChartPrimaryView!
    @IBOutlet weak var rightAxis: AxisView!
    @IBOutlet weak var leftAxis: AxisView!
    @IBOutlet weak var topAxis: AxisView!
    @IBOutlet weak var bottomAxis: AxisView!
    
    var chartModels: [StandardChartModel]? {
        didSet {
            self.displayView.newChartModels = chartModels
        }
    }
    
    var renameUserCallSummaryHistoryModel: UserCallSummaryHistoryModel? {
        didSet {
            self.displayView.renameUserCallSummaryHistoryModel = renameUserCallSummaryHistoryModel
        }
    }
    
    var renameTeamCallSummaryHistoryModel: TeamCallSummaryHistoryModel? {
        didSet {
            self.displayView.renameTeamCallSummaryHistoryModel = renameTeamCallSummaryHistoryModel
        }
    }
    
    
    var bottomLabels: [String]?
    var leftLabels: [String]?
    var rightLabels: [String]?
    
//    var bottomLabels: [String]? {
//        didSet {
//
//        }
//    }
    
//    public func setChartModels(chartModels: [StandardChartModel]) {
//        self.chartModels = chartModels
//        
//        //self.setupAxisLabels()
//    }
    
    
//    private func setupAxisLabels() {
//        self.bottomAxis.addLabels()
//    }
    
    /*
     override func layoutSubviews() {
         self.lineGraphLayer?.setNeedsLayout()
         self.lineGraphLayer?.setNeedsDisplay()
         self.gridLineLayer?.setNeedsLayout()
         self.gridLineLayer?.setNeedsDisplay()
     }
     */
    
    
    public func updateDisplay() {
        
        self.displayView.setNeedsLayout()
        self.displayView.setNeedsDisplay()
        
        self.bottomAxis.addLabels(strs: bottomLabels)
        self.leftAxis.addLabels(strs: leftLabels)
        self.rightAxis.addLabels(strs: rightLabels)
        
    }
    
    override func layoutSubviews() {
        
        self.displayView.setNeedsLayout()
        self.displayView.setNeedsDisplay()
        
        
        
        // MARK: TODO
        // this should be really done via attributes since this deletes and re creates all the labels based on new dimesions. but meh,
        self.bottomAxis.addLabels(strs: bottomLabels)
        self.leftAxis.addLabels(strs: leftLabels)
        self.rightAxis.addLabels(strs: rightLabels)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit(){
        let viewFromXib = Bundle.main.loadNibNamed("ChartStandardView", owner: self, options: nil)![0] as! UIView
        viewFromXib.frame = self.bounds
        addSubview(viewFromXib)
    }
}
