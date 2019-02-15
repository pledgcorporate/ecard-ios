//
//  ViewController.swift
//  PledgKit
//
//  Created by Lukasz Zajdel on 12/13/2018.
//  Copyright (c) 2018 Lukasz Zajdel. All rights reserved.
//

import UIKit
import PledgKit


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
      
    }
    
    
    @IBAction func pushButtonPressed(_ sender: Any) {
        
        let product1 = Product(label: "Chambre 1", priceCents: 2000)
        let product2 = Product(label: "Chambre 2", priceCents: 3500)
        let product3 = Product(label: "Chambre 3", priceCents: 90)
        
        let transactionSettings =  TransactionConfiguration(title: "Exemple de titre", subtitle: "Exemple de sous-titre", merchantId: "mer_8ec99f9a-f650-4893-a4a3-16f20e16bb66", email: "benoit@pledg.co", amountCents: 5590, reference: "order_123", currency: "EUR", products:[product1,product2,product3], lang:"fr_FR")
        
        
        let viewSettings = ViewConfiguration()
        viewSettings.title = "Pledg"
        viewSettings.hidesBackButton = false
        viewSettings.cancelButtonDisplayStyle = .none
        
        let pledgViewController = PledgViewController.createNew(with: transactionSettings, viewSettings: viewSettings, errorSettings: CustomErrorConfiguration()) {  [unowned self] _, result in
            
            self.navigationController?.popViewController(animated: true)
            
            switch result{
            case .cancelled:break
            case .success(let card):
                self.showAlertInfoForVirtualCard(card: card)
            case .failed:break
            case .apiFailed:break
            }
        }
        
        pledgViewController.systemBackButtonWillPopViewControllerHandler = { _ in
            print("Will back from standard system back button item")
        }
        
        navigationController?.pushViewController(pledgViewController, animated: true)
        
    }
    
    func showDefault(){
        
        var products = [Product]()
        
        products.append(Product(label: "Product name #1", priceCents: 2000))
        products.append(Product(label: "Product name #2", priceCents: 3500))
        products.append(Product(label: "Product name #3", priceCents: 90))
        
        let transactionSettings =  TransactionConfiguration(title: "Title", subtitle: "Subtitle", merchantId: "mer_8ec99f9a-f650-4893-a4a3-16f20e16bb66", email: "exmaple@exmaple.co", amountCents: 5590, reference: "order_123", currency: "EUR", products:products, lang:"en_GB")
        
        
        let pledgViewController = PledgViewController.createNew(with: transactionSettings) { vc , result in
            
            vc.presentingViewController?.dismiss(animated: true){
                
                switch result{
                case .cancelled:break // Function to call when the user closes himself the iframe without completing the payment
                case .success(let card):
                    print("Success transaction card:\(card)")
                case .failed(let error):
                    if let error = error{
                        print("Fail transaction error:\(error.localizedDescription)")
                    }else{
                        print("Fail transaction unknwon")
                    }
                case .apiFailed(let apiError):
                    print("Fail transaction api message:\(apiError.localizedDescription) ")
                }
            }
        }
        
        present(UINavigationController(rootViewController: pledgViewController), animated: true, completion: nil)
        
    }
    
    @IBAction func modalButtonPressed(_ sender: Any) {
        
        let product1 = Product(label: "Chambre 1", priceCents: 2000)
        let product2 = Product(label: "Chambre 2", priceCents: 3500)
        let product3 = Product(label: "Chambre 3", priceCents: 90)
        
        let transactionSettings =  TransactionConfiguration(title: "Exemple de titre", subtitle: "Exemple de sous-titre", merchantId: "mer_8ec99f9a-f650-4893-a4a3-16f20e16bb66", email: "benoit@pledg.co", amountCents: 5590, reference: "order_123", currency: "EUR", products:[product1,product2,product3], lang:"en_GB")
        
        let viewSettings = ViewConfiguration()
        viewSettings.title = "Pledg"
        viewSettings.cancelButtonTitle = "Cancel"
        viewSettings.cancelButtonDisplayStyle = .left
        
        let pledgViewController = PledgViewController.createNew(with: transactionSettings, viewSettings: viewSettings) { vc , result in
            
            
            vc.presentingViewController?.dismiss(animated: true){
                
                switch result{
                case .cancelled:break
                case .success(let card):
                    self.showAlertInfoForVirtualCard(card: card)
                case .failed:break
                case .apiFailed:break
                }
            }
        }
        
        let navigationController = UINavigationController(rootViewController: pledgViewController)
        
        present(navigationController, animated: true, completion: nil)
        
    }
    
    func showAlertInfoForVirtualCard(card:VirtualCard){
        
        
        var items:[String] = []
        
        if let value = card.uid{
            items.append("uid:\(value)")
        }
        if let value = card.purchase?.uid{
            items.append("purchase.uid:\(value)")
        }
        if let value = card.account?.uid{
            items.append("account.uid:\(value)")
        }
        if let value = card.state{
            items.append("state:\(value)")
        }
        if let amount = card.amount, let symbol = card.currencySymbol{
            items.append("amount:\(amount) \(symbol)")
        }
        if let value = card.cardNumber{
            items.append("cardNumber:\(value)")
        }
        
        
        let message = (items as NSArray).componentsJoined(by: "\n\n")
        
        let alertController = UIAlertController(title:"Purchase success", message:message , preferredStyle: .alert)
        
        
        let cancel = UIAlertAction(title: "Ok", style: .cancel) { (action) -> Void in
            
        }
        
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}



class CustomErrorConfiguration:PledgKit.ErrorConfiguration{
    
     let errorTryAgainButtonTitle:String = "Try again"
     let apiErrorMainLabelTitle:String = "Pledg error"
     let errorMainLabelTitle:String = "Connection error"
     let unknownErrorDescriptionLabelTitle:String = "Unknown error"
    
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

