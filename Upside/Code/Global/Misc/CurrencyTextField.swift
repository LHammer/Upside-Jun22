//
//  CurrencyTextField.swift
//  Upside
//
//  Created by Luke Hammer on 5/20/22.
//


import UIKit

// MARK: LH changes - no need for tag possibly
//protocol CurrencyTextFieldDelegate {
//    func getAmountAsCleanDouble(amount: Double, tag: Int)
//}

class CurrencyTextField: UITextField {
    
    // MARK: LH changes
    //var currencyTextFieldDelegate: CurrencyTextFieldDelegate!
    var cellTag: Int?

    var passTextFieldText: ((String, Double?) -> Void)?
    
    var currency: CurrencyModel? {
        didSet {
            guard let currency = currency else { return }
            numberFormatter.currencyCode = currency.code
            numberFormatter.locale = Locale(identifier: currency.locale)
        }
    }
    
    //Used to send clean double value back
    private var amountAsDouble: Double?
    
    var startingValue: Double? {
        didSet {
            let nsNumber = NSNumber(value: startingValue ?? 0.0)
            self.text = numberFormatter.string(from: nsNumber)
        }
    }
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        //locale and currencyCode set in currency property observer
        return formatter
    }()
    
    private var roundingPlaces: Int {
        return numberFormatter.maximumFractionDigits
    }
    
    private var isSymbolOnRight = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //If using in SBs
        setup()
    }
    
    private func setup() {
        self.textAlignment = .right
        self.keyboardType = .numberPad
        self.contentScaleFactor = 0.5
        delegate = self
        
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    //AFTER entered string is registered in the textField
    @objc private func textFieldDidChange() {
        self.updateTextField()
    }
    
    public func update() {
        self.updateTextField()
    }
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//    }
//
    //Placed in separate method so when the user selects an account with a different currency, it will immediately be reflected
    private func updateTextField() {
        
        
        var cleanedAmount = ""
        
        for character in self.text ?? "" {
            if character.isNumber {
                cleanedAmount.append(character)
            }
        }
        
        if isSymbolOnRight {
            cleanedAmount = String(cleanedAmount.dropLast())
        }
        
        //Format the number based on number of decimal digits
        if self.roundingPlaces > 0 {
            //ie. USD
            let amount = Double(cleanedAmount) ?? 0.0
            amountAsDouble = (amount / 100.0)
            let amountAsString = numberFormatter.string(from: NSNumber(value: amountAsDouble ?? 0.0)) ?? ""
            
            self.text = amountAsString
        } else {
            //ie. JPY
            let amountAsNumber = Double(cleanedAmount) ?? 0.0
            amountAsDouble = amountAsNumber
            self.text = numberFormatter.string(from: NSNumber(value: amountAsNumber)) ?? ""
        }
        
        passTextFieldText?(self.text!, amountAsDouble)
        
        // MARK: LH changes.
        // Currency must be set first. en_US | $0.00 may be a good alternative
        if currency == nil {
            currency = CurrencyModel(locale: "en_US", amount: 0.00) // should be defualt to the user.
        }
        
        currency!.amount = amountAsDouble!
    }
    
    //Prevents the user from moving the cursor in the textField
    //Source: https://stackoverflow.com/questions/16419095/prevent-user-from-setting-cursor-position-on-uitextfield
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }
}


extension CurrencyTextField: UITextFieldDelegate {
    
    //BEFORE entered string is registered in the textField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // LH added the below to ensure number doesn't get to big.
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""
        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }
        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        // make sure the result is under 16 characters
        if updatedText.count >= 18 {
            return false
        }
        
        
        // MARK: Handles the right hand side stuff.
        let lastCharacterInTextField = (textField.text ?? "").last
        //Note - not the most straight forward implementation but this subclass supports both right and left currencies
        if string == "" && lastCharacterInTextField!.isNumber == false {
            //For hitting backspace and currency is on the right side
            isSymbolOnRight = true
        } else {
            isSymbolOnRight = false
        }
        
        return true
    }
}
