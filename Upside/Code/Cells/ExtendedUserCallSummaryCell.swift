//
//  ExtendedUserCallSummaryCell.swift
//  Upside
//
//  Created by Luke Hammer on 6/1/22.
//

import UIKit

class ExtendedUserCallSummaryCell: UITableViewCell {
    
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var headingHolderView: UIView!
    @IBOutlet weak var callTotalDeltaIndicatorImg: UIImageView!
    @IBOutlet weak var callAttainmentDeltaIndicatorImg: UIImageView!
    @IBOutlet weak var closedWonDeltaIndicatorImg: UIImageView!
    
    @IBOutlet weak var chart: ChartStandardView!
    
    
    /* Period */
    @IBOutlet weak var callPeriodGroupDescriptionLabel: UILabel!
    var callPeriodGroupDescription: String? {
        didSet {
            if callPeriodGroupDescription != nil {
                self.callPeriodGroupDescriptionLabel.text = self.callPeriodGroupDescription
            }
        }
    }
    
    /* Call last made */
    @IBOutlet weak var lastCallTimestampLabel: UILabel!
    var lastCallTimestamp: Double? {
        didSet {
            
            if lastCallTimestamp != nil {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = NSLocale.current
                dateFormatter.dateFormat = "MMM d, h:mm a"
                let date = Date(timeIntervalSince1970: lastCallTimestamp!)
                
//                var timePastString = ""
//
//                if let daysBetween = getDaysBetween(date1: date, date2: Date()) {
//                    let intStr = String(daysBetween)
//                    timePastString = " (" + intStr + " days ago)"
//                }
                
                
                // let fullStr = "last call: " + dateFormatter.string(from: date) // + timePastString
                let fullStr = dateFormatter.string(from: date)
                self.lastCallTimestampLabel.text = fullStr
            }
        }
    }
    
    // MARK: TODO move to global function
    
    private func getDaysBetween(date1: Date, date2: Date) -> Int? {
        
        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: date1)
        let date2 = calendar.startOfDay(for: date2)

        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day
        
    }
    
    
    
    /* Call */
    @IBOutlet weak var totalCallAmountLabel: UILabel!
    var totalCallAmount: Double? {
        didSet {
            if totalCallAmount != nil {
                self.totalCallAmountLabel.text = CurrencyModel(locale: "en_US", amount: totalCallAmount!).format
            }
        }
    }
    
    /* Yet to close */
    @IBOutlet weak var yetToCloseLabel: UILabel!
    var yetToCloseAmount: Double? {
        didSet {
            if yetToCloseAmount != nil {
                self.yetToCloseLabel.text = formatShortHandCurrency(num: yetToCloseAmount!)
            }
        }
    }
    
    /* forecast attainment */
    @IBOutlet weak var forecastAttainmentLabel: UILabel!
    var forecastedAttainment: Double? {
        didSet {
            if forecastedAttainment != nil {
                self.forecastAttainmentLabel.text = String(format: "%.2f", 100.0 * self.forecastedAttainment!) + "%"
                
            }
        }
    }
    
    /* quota */
    @IBOutlet weak var quotaLabel: UILabel!
    var quota: Double? {
        didSet {
            if quota != nil {
                self.quotaLabel.text = formatShortHandCurrency(num: quota!)
                // CurrencyModel(locale: "en_US", amount: quota!).format
            }
        }
    }
    
    
    
    /* closed won */
    @IBOutlet weak var closedWonLabel: UILabel!
    var closedWon: Double? {
        didSet {
            if closedWon != nil {
                self.closedWonLabel.text = CurrencyModel(locale: "en_US", amount: closedWon!).format
            }
        }
    }
    
    
    /* call total delta */
    @IBOutlet weak var callTotalDeltaLabel: UILabel!
    var callTotalDelta: Double? {
        didSet {
            if self.callTotalDelta == nil {
                self.callTotalDeltaLabel.text = "n/a"
            } else {
                
                // callTotalDeltaIndicatorImg
                
                if callTotalDelta! < 0 {
                    self.callTotalDeltaIndicatorImg.image = UIImage(named: "red_down")
                } else if callTotalDelta! > 0 {
                    self.callTotalDeltaIndicatorImg.image = UIImage(named: "green_up")
                } else {
                    self.callTotalDeltaIndicatorImg.image = nil
                }
                
                self.callTotalDeltaLabel.text = formatShortHandCurrency(num: self.callTotalDelta!)
            }
        }
    }
    
    
    /* call percentage delta */
    @IBOutlet weak var callPercentageDeltaLabel: UILabel!
    var callPercentageDelta: Double? {
        didSet {
            if self.callPercentageDelta == nil {
                self.callPercentageDeltaLabel.text = "n/a"
            } else {
                
                if callPercentageDelta! < 0 {
                    self.callAttainmentDeltaIndicatorImg.image = UIImage(named: "red_down")
                } else if callTotalDelta! > 0 {
                    self.callAttainmentDeltaIndicatorImg.image = UIImage(named: "green_up")
                } else {
                    self.callAttainmentDeltaIndicatorImg.image = nil
                }
                
                let str = String(format: "%.2f", 100.0 * self.callPercentageDelta!) + "%"
                self.callPercentageDeltaLabel.text = str
                
            }
        }
    }
    
    
    /* closed won delta */
    @IBOutlet weak var closedWonDeltaLabel: UILabel!
    var closedWonDelta: Double? {
        didSet {
            if closedWonDelta == nil {
                self.closedWonDeltaLabel.text = "n/a"
            } else {
                
                if closedWonDelta! < 0 {
                    self.closedWonDeltaIndicatorImg.image = UIImage(named: "red_down")
                } else if closedWonDelta! > 0 {
                    self.closedWonDeltaIndicatorImg.image = UIImage(named: "green_up")
                } else {
                    self.closedWonDeltaIndicatorImg.image = nil
                }
                
                self.closedWonDeltaLabel.text = formatShortHandCurrency(num: closedWonDelta!)
            }
        }
    }
    
    /* High / Low */
    @IBOutlet weak var maxCallLabel: UILabel!
    var maxCall: Double? {
        didSet {
            if maxCall != nil {
                maxCallLabel.text = formatShortHandCurrency(num: maxCall!)
            }
        }
    }
    
    
    @IBOutlet weak var minCallLabel: UILabel!
    var minCall: Double? {
        didSet {
            if minCall != nil {
                minCallLabel.text = formatShortHandCurrency(num: minCall!)
            }
        }
    }
    
    /* Closed won correction note */
    @IBOutlet weak var closedWonCorrectionNoteLabel: UILabel!
    var closedWonAmountCorrectionAmount: Double? {
        didSet {
            if closedWonAmountCorrectionAmount == nil || closedWonAmountCorrectionAmount == 0.0 {
                closedWonCorrectionNoteLabel.text = ""
            } else {
                closedWonCorrectionNoteLabel.text = "incl " + formatShortHandCurrency(num: closedWonAmountCorrectionAmount!) + " of corrections"
                
            }
        }
    }
    
    
    /*
     redBox.layer.cornerRadius = 25
     redBox.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
     view.addSubview(redBox)
     */
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.holderView.layer.cornerRadius = 10.0
        self.headingHolderView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.headingHolderView.layer.cornerRadius = 10.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
