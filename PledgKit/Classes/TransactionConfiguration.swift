//
//  ConfigurationSettings.swift
//  Alamofire
//
//  Created by Lukasz Zajdel on 03/12/2018.
//

import Foundation


//-----------------------------------

public struct Product:Codable {
    
    let label:String
    let priceCents:Int
    
    public init(label:String,priceCents:Int){
        self.label = label
        self.priceCents = priceCents
    }
    var dict:[String:Any]{
        return [PledgUrlParametersName.productLabelParameter:label, PledgUrlParametersName.productPriceParameter:priceCents]
    }
}

public struct TransactionConfiguration{
    
    let title:String
    let subtitle:String
    let merchantId:String
    let email:String
    let amountCents:Int
    let reference:String
    let currency:String
    let lang:String?
    

    let products:[Product]?
    
    public init(title:String,subtitle:String,merchantId:String,email:String,amountCents:Int,reference:String,currency:String, products:[Product]? = nil, lang:String? = nil  ) {
        
        self.title = title
        self.subtitle = subtitle
        self.merchantId = merchantId
        self.email = email
        self.amountCents = amountCents
        self.reference = reference
        self.currency = currency
        self.lang = lang
        self.products = products
        
    }
    
}

extension TransactionConfiguration{
    
    var url:URL{
        
        var components = URLComponents()
        
        components.scheme = PledgSettings.baseURLScheme
        components.host = PledgSettings.baseURLString
        
        if let versionPath = PledgSettings.baseURLApiVersion, versionPath.isEmpty == false{
            components.path = versionPath
        }
        
        var queryItems:[URLQueryItem] = []
        
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.embededParameter, value: "1"))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.sdkMobileParameter, value: "1"))
        
        if let languageCode = lang{
            
            queryItems.append(URLQueryItem(name: PledgUrlParametersName.langParameter, value: languageCode))
            
        }else if let languageCode = Locale.preferredLanguages.first{
            
            queryItems.append(URLQueryItem(name: PledgUrlParametersName.langParameter, value: languageCode))
        }
        
        
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.titleParameter, value: title))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.subtitleParameter, value: subtitle))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.merchantIdParameter, value: merchantId))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.emailParameter, value: email))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.amountCentsParameter, value: "\(amountCents)"))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.referenceParameter, value: reference))
        queryItems.append(URLQueryItem(name: PledgUrlParametersName.currencyParameter, value: currency))
    
        if let products = products, products.isEmpty == false {
            
            let items = products.compactMap({ $0.dict})
            
            do {
                
                let jsonData = try JSONSerialization.data(withJSONObject: items, options: [])
                
                if let decodedString = String(data: jsonData, encoding: .utf8){
                    
                    queryItems.append(URLQueryItem(name: PledgUrlParametersName.productsParameter, value: decodedString ))
                }
                
            }catch let error{
                print("JSON error:\(error)")
            }
            
            
        }
        
        components.queryItems = queryItems
    
        return components.url!
        
    }
    
}

//-----------------------------------

