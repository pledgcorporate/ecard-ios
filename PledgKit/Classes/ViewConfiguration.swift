//
//  ViewConfiguration.swift
//  PledgKit
//
//  Created by Lukasz Zajdel on 13/12/2018.
//

import Foundation

public class ViewConfiguration{
    
    public var title:String = "Pledg"
    
    public enum BarButtonItemDisplayStyle {
        
        case none
        case left
        case right
        case arrow
    }
    
    public var cancelButtonTitle:String = "Cancel"
    public var cancelButtonDisplayStyle:BarButtonItemDisplayStyle = .left
    public var hidesBackButton:Bool = true
    
    public init(){}
    
}
