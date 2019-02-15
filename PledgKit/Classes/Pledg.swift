//
//  PledgSettings.swift
//  Alamofire
//
//  Created by Lukasz Zajdel on 03/12/2018.
//

import Foundation

struct PledgSettings{
    
    static let baseURLScheme = "https"
    static let baseURLString = "ecard-front-mobile.herokuapp.com"
    static let baseURLApiVersion:String? = nil
    
    static let jsCompletionHandlerName = "callbackHandler"
    static let jsCancelMethodName = "cancelButtonPressed();"
}


struct PledgUrlParametersName {
    
    static let embededParameter = "embeded" // should be 1
    static let sdkMobileParameter = "sdk_mobile" // should be 1
    
    static let titleParameter = "title"
    static let subtitleParameter = "subtitle"
    static let merchantIdParameter = "merchant_uid"
    static let emailParameter = "email"
    
    static let amountCentsParameter = "amount_cents"
    static let referenceParameter = "reference"
    static let currencyParameter = "currency"
    static let langParameter = "lang"
    static let productsParameter = "products"
    
    
    static let productPriceParameter = "priceCents"
    static let productLabelParameter = "label"
}


struct EventPayload: Codable {
    
    public let error: ApiError?
    public let virtualCard:VirtualCard?
    
}

/*
virtualCard =         {
    account =             {
        uid = "acc_485dbb63-9259-4754-aa4b-2d7a272f1209";
    };
    amount = "55.9";
    "amount_cents" = 5590;
    "card_number" = 5000056655665557;
    created = "13-12-2018";
    currency = EUR;
    "currency_symbol" = "\U20ac";
    cvc = 897;
    "expiration_date" = "30-06-2018";
    "expiry_month" = 06;
    "expiry_year" = 2018;
    purchase =             {
        uid = "pur_ef649c4a-5eb4-4f79-ab51-399802e0f968";
    };
    state = CREATED;
    uid = "vcar_0374048e-a342-42d5-a1ad-345ae5dd6d51";
    updated = "13-12-2018";
    "vcp_reference" = 5000056655665557123;
};
*/

public struct VirtualCard: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case account
        case amount
        case amountCents = "amount_cents"
        case cardNumber = "card_number"
        
        case created
        case currency
        case currencySymbol = "currency_symbol"
        case cvc
        case expirationDate = "expiration_date"
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
        case purchase
        case state
        case uid
        case updated
        case vcpReference = "vcp_reference"
    }
    
    public struct Account:Codable{
        
        public let uid:String
    }
    
    public  let account:Account?
    
    public let amount:Float?
    
    public let amountCents:Int?
    
    public let cardNumber:String?
    
    let created:String?
    
    let currency:String?
    
    public let currencySymbol:String?
    
    let cvc:String?
    
    let expirationDate:String?
    
    let expiryMonth:String?
    
    let expiryYear:String?
    
    public struct Purchase:Codable{
        
        public let uid:String
    }
    
    public let purchase:Purchase?
    
    public let state:String?
    
    public let uid:String?
    
    let updated:String?
    
    let vcpReference:String?
    
    
}


public struct ApiError:Codable {
    
    public let message: String?
    public let type: String?
    
    public var localizedDescription:String{
        return message ?? "Unknown error"
    }
}

enum ApiEvent:String,Codable{
    case failed = "PLEDG_ERROR"
    case cancel = "PLEDG_CANCEL_CLOSE"
    case success = "PLEDG_SUCCESS"
    case scrollToTop = "PLEDG_SCROLL_TO_TOP"
}

class ApiEventRootResponse:Codable{
    
    public let name: ApiEvent
    public let payload: EventPayload?
    
}


extension UIImage {
    
    convenience init?(podAssetName: String) {
        let podBundle = Bundle(for: PledgViewController.self)
        
        /// A given class within your Pod framework
        guard let url = podBundle.url(forResource: "PledgKit",
                                      withExtension: "bundle") else {
                                        return nil
                                        
        }
        
        self.init(named: podAssetName,
                  in: Bundle(url: url),
                  compatibleWith: nil)
    }
}


extension UIStoryboard{
    
    static func podStoryboard(name:String = "Main")->UIStoryboard{
        
        let podBundle = Bundle(for: PledgViewController.self)
        
        let bundleURL = podBundle.url(forResource: "PledgKit", withExtension: "bundle")
        let bundle = Bundle(url: bundleURL!)!
        let storyboard = UIStoryboard(name: name, bundle: bundle)
        
        return storyboard
    }
    
}
