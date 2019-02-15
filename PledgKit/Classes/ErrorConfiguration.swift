//
//  PledgErrorSettings.swift
//  PledgKit
//
//  Created by Lukasz Zajdel on 13/12/2018.
//

import Foundation

public enum ErrorReason{
    case api(ApiError?)
    case other(Error?)
}


public enum ErrorTriggerAction{
    case callCompletionHandler
    case displayErrorInternaly
}

public class ErrorViewSettings{
    
    var title:String?
    var subtitle:String?
    var tryAgainTitle:String?
    
    public init(title:String?,subtitle:String?,tryAgainTitle:String?) {
        self.title = title
        self.subtitle = subtitle
        self.tryAgainTitle = tryAgainTitle
    }

}


public protocol ErrorConfiguration{
    func localizedInfo(for reason:ErrorReason)->ErrorViewSettings
    func action(for reason:ErrorReason)->ErrorTriggerAction
}

public class DefaultErrorConfiguration:ErrorConfiguration{
    
    public var errorTryAgainButtonTitle:String = "Try again"
    public var apiErrorMainLabelTitle:String = "Pledg error"
    public var errorMainLabelTitle:String = "Connection error"
    public var unknownErrorDescriptionLabelTitle:String = "Unknown error"
    
    public func action(for reason:ErrorReason)->ErrorTriggerAction{
        
        return .displayErrorInternaly
    }
    
    public func localizedInfo(for reason:ErrorReason)->ErrorViewSettings{
        
        var failTitle:String?
        var failDescription:String?
        let tryAgainTitle:String?
        
        switch reason {
        case .other(let error):
            
            failTitle = errorMainLabelTitle
            tryAgainTitle = errorTryAgainButtonTitle
            
            if let localizedDescription = error?.localizedDescription{
                failDescription = localizedDescription
            }else{
                failDescription = unknownErrorDescriptionLabelTitle
            }
            
        case .api(let error):
            
            failTitle = apiErrorMainLabelTitle
            tryAgainTitle = nil
            
            if let localizedDescription = error?.message{
                failDescription = localizedDescription
            }else{
                failDescription = unknownErrorDescriptionLabelTitle
            }
        }
        
        return ErrorViewSettings(title: failTitle, subtitle: failDescription, tryAgainTitle: tryAgainTitle)
    }
}
