//
//  LoadingViewController.swift
//
//  Created by Lukasz Zajdel on 08.08.2015.
//  Copyright (c) 2015 Gotap. All rights reserved.
//

import UIKit

class PledgLoadingViewController: UIViewController {

    var viewSettings:ViewConfiguration!
    
    var loadingText:String = NSLocalizedString("Loading ...", comment: ""){
        didSet{
            if let loadingLabel = loadingLabel{
                loadingLabel.text = loadingText
            }
        }
    }
    
    @IBOutlet weak var loadingLabel: UILabel!{
        didSet{
            loadingLabel.text = loadingText
        }
    }
    
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    
    static func newController(loadingText:String)->PledgLoadingViewController{
        
        let vc = UIStoryboard.podStoryboard().instantiateViewController(withIdentifier: "PledgLoadingViewController") as! PledgLoadingViewController
        
        vc.loadingText = loadingText
        
        return vc
    }
}
