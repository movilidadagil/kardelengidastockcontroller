//
//  CustomTextField.swift
//  AnyVcNavigator
//
//  Created by Hasan Hüseyin Ali Gül on 3.04.2022.
//  Copyright © 2022 Arjun Baru. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
        
        let padding : CGFloat
        init(padding:CGFloat){
            
            self.padding = padding
            super.init(frame: .zero)
            layer.cornerRadius = 25
                
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        override func textRect(forBounds bounds: CGRect) -> CGRect {
            return bounds.insetBy(dx: padding, dy: 0)
        }
        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            return bounds.insetBy(dx: padding, dy: 0)
        }
        
        override var intrinsicContentSize: CGSize {
            return .init(width: 0, height: 50)
        }
    
}
