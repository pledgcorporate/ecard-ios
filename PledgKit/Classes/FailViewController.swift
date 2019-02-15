//
//  FailViewController.swift
//  Radioline
//
//  Created by Lukasz Zajdel on 28.05.2018.
//  Copyright © 2018 Gotap. All rights reserved.
//

import Foundation


class PledgFailViewController:UIViewController{
    
    var viewSettings:ViewConfiguration!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var actionButtonTitle:String?
    
    var failTitle:String? =  NSLocalizedString("Error", comment: "")
    var failDescription:String?
    
    var actionHandler:(()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = failTitle ?? title
        descriptionLabel.text = failDescription
        
        
        if let mockupAction = actionButtonTitle{
            actionButton.setTitle(mockupAction, for: [])
            actionButton.isHidden = false
        }else{
            actionButton.isHidden = true
        }
        
        
        
    }
    @IBAction func actionButtonPressed(_ sender: Any) {
        
        actionHandler?()
    }
    
    static func newController(title:String,description:String, actionTitle:String? = nil, icon:UIImage? = nil, actionHandler:(()->Void)? = nil )->PledgFailViewController{
        
        
        
        let vc = UIStoryboard.podStoryboard().instantiateViewController(withIdentifier: "PledgFailViewController") as! PledgFailViewController
        
        vc.title = title
        vc.failTitle = title
        vc.failDescription = description
        
        vc.actionButtonTitle = actionTitle
        vc.actionHandler = actionHandler
        
        return vc
        
    }
}
