
import UIKit



public extension PledgViewController{
    
    static public func createNew(with settings:TransactionConfiguration, viewSettings:ViewConfiguration? = nil, errorSettings:ErrorConfiguration? = nil,  completion:PledgDissmissHandler? = nil )->PledgViewController{
        
        let vc = UIStoryboard.podStoryboard().instantiateViewController(withIdentifier: "PledgViewController") as! PledgViewController
        vc.transactionSettings = settings
        vc.viewSettings = viewSettings ??  ViewConfiguration()
        vc.errorSettings = errorSettings ??  DefaultErrorConfiguration()
        vc.dissmisHandler = completion
        return vc
        
    }
}



public enum PledgResult{
    case success(VirtualCard)
    case apiFailed(ApiError)
    case failed(Error?)
    case cancelled
}

public typealias PledgDissmissHandler = ((PledgViewController,PledgResult)->Void)

public final class PledgViewController: UIViewController {
    
    
    fileprivate var dissmisHandler:PledgDissmissHandler? = nil
    public var systemBackButtonWillPopViewControllerHandler:((PledgViewController)->Void)? = nil
    
    fileprivate var transactionSettings:TransactionConfiguration!
    fileprivate var viewSettings:ViewConfiguration =  ViewConfiguration()
    fileprivate var errorSettings:ErrorConfiguration =  DefaultErrorConfiguration()
    
    
    
    fileprivate let transitioningManager = PledgeTransitionDelegate()
    
    private func setupPresentation(){
        
        transitioningDelegate = transitioningManager
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
        
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupPresentation()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupPresentation()
        
    }
  
    private lazy var cancelBarButtonItem:UIBarButtonItem = {
        
        return UIBarButtonItem(title: self.viewSettings.cancelButtonTitle, style: .plain, target: self, action: #selector(PledgViewController.cancelButtonPressed(_:)))
        
    }()
    
    private lazy var backBarButtonItem:UIBarButtonItem = {
        
        
        let item =  UIBarButtonItem(image:
            UIImage(podAssetName: "backBtn")!, style: .plain, target: self, action: #selector(PledgViewController.cancelButtonPressed(_:)))
        item.imageInsets = UIEdgeInsets(top: 2, left: -8, bottom: 0, right: 0)
        
        return item
        
        
    }()
    
    private func callDissmisHandler(with result:PledgResult){
        
        self.dissmisHandler?(self,result)
        
        self.dissmisHandler = nil
        
    }
    
    public func cancel(){
        
        if let webViewController = activeViewController as? PledgeWebViewController{
            
            webViewController.evaluateJavaScriptCancel {
                
                self.callDissmisHandler(with: .cancelled)
            }
            
        }else{
           
            self.callDissmisHandler(with: .cancelled)
        }
        
    }
    
    @objc func cancelButtonPressed(_ sender: Any){
     
        cancel()
    }
    
    func updateCancelButton(){
        
        cancelBarButtonItem.title = viewSettings.cancelButtonTitle
        
        switch viewSettings.cancelButtonDisplayStyle {
        case .left:
            self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        case .right:
            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        case .arrow:
            self.navigationItem.leftBarButtonItem = backBarButtonItem
        default:break
        }
        
        
        
    }
    
    override public func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = viewSettings.title
        navigationItem.hidesBackButton = viewSettings.hidesBackButton
        
        updateCancelButton()
        
        displayWebViewController(animated: false)
    }
    
    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if parent == nil && viewSettings.cancelButtonDisplayStyle == .none && navigationItem.hidesBackButton == false{
            
            if let webViewController = activeViewController as? PledgeWebViewController{
                webViewController.evaluateJavaScriptCancel()
            }
            
            self.systemBackButtonWillPopViewControllerHandler?(self)
            self.systemBackButtonWillPopViewControllerHandler = nil
            
        }
        
        
    }
    
    
    
    func showError(for reason:ErrorReason, animated:Bool = true){
        
        let failController = self.storyboard!.instantiateViewController(withIdentifier: "PledgFailViewController") as! PledgFailViewController
        failController.viewSettings = viewSettings
        
        let info = errorSettings.localizedInfo(for: reason)
        
        failController.failTitle = info.title
        failController.failDescription = info.subtitle
        failController.actionButtonTitle = info.tryAgainTitle
        
        failController.actionHandler = { [unowned self] in
            self.displayWebViewController(animated: true)
        }
        
        setActiveViewController(vc:  failController, animated: animated)
        
    }
    
    //
    // -----------------
    fileprivate func displayWebViewController(animated:Bool = true){
        
        let webViewController = self.storyboard!.instantiateViewController(withIdentifier: "PledgeWebViewController") as! PledgeWebViewController
        webViewController.settings = transactionSettings
        
        webViewController.webKitErrorHandler = {  [unowned self] error, vc in
            
            let action:ErrorTriggerAction = self.errorSettings.action(for: .other(error))
            
            
            switch action {
            case .displayErrorInternaly:
                self.showError(for: .other(error))
            case .callCompletionHandler:
                self.callDissmisHandler(with: .failed(error))
            }
            
        }
        
        
        
        webViewController.didReceiveEventHandler = {  [unowned self] eventResponse, vc in
            
            let apiEvent:ApiEvent = eventResponse.name
            switch apiEvent {
            case .scrollToTop:
                self.logError()
            case .cancel:
                self.callDissmisHandler(with: PledgResult.cancelled)
           
            case .success:
                //self.logError()
                if let card:VirtualCard = eventResponse.payload?.virtualCard{
                    
                    let result:PledgResult =  PledgResult.success(card)
                    
                    self.callDissmisHandler(with: result)
                    
                }else{
                    
                    self.callDissmisHandler(with: .failed(nil))
                }
                
                
                //
            case .failed:
                
                let action:ErrorTriggerAction = self.errorSettings.action(for: .api(eventResponse.payload?.error))
                
                switch action {
                case .displayErrorInternaly:
                    self.showError(for: .api(eventResponse.payload?.error))
                case .callCompletionHandler:
                    if let error = eventResponse.payload?.error{
                        self.callDissmisHandler(with: .apiFailed(error))
                    } else{
                        self.callDissmisHandler(with: .failed(nil))
                    }
                }
            }
         
            /*
            switch eventResponse.name {
            case .scrollToTop:
                self.logError()
            case .cancel:
                self.callDissmisHandler(with: .cancelled)
            case .error:
                
                let action:ErrorTriggerAction = self.errorSettings.action(for: .api(eventResponse.payload?.error))
                
                switch action {
                case .displayErrorInternaly:
                    self.showError(for: .api(eventResponse.payload?.error))
                case .callCompletionHandler:
                    self.callDissmisHandler(with: .failed(eventResponse.payload?.error))
                }
            case .success:
                self.callDissmisHandler(with: .success(eventResponse.payload?.virtualCard))
            }
 */
        }
        
        
        
        setActiveViewController(vc:  webViewController, animated: animated)
    }
   
    func logError(){
        
    }
    
    
    // Child management
    // -----------------
    
    fileprivate enum ChangeAnimationTransition{
        case alpha
        case slideVertical (fromTopToBottom:Bool)
        case slideHorizontal (fromLeftToRight:Bool)
    }
    
    @IBOutlet weak var activeViewControllerContainerView: UIView!

    fileprivate var animationTransition:ChangeAnimationTransition = .alpha
    fileprivate var animatedFlag:Bool = false
    
    fileprivate func setActiveViewController(vc: UIViewController, animated:Bool){
        
        animatedFlag = animated
        activeViewController = vc
    }
    

    private (set) var activeViewController: UIViewController? {
        didSet {
            
            
            if oldValue != activeViewController{
                
                if let old = oldValue, let new = activeViewController, animatedFlag{
                    
                    
                    switch animationTransition{
                    case .alpha:
                        cycleFromViewController(from: old, to: new)
                    case .slideVertical(let fromTopToBottom):
                        cycleSlideVerticalFromViewController(from: old, to: new, fromTopToBottom: fromTopToBottom, withDuration: 0.6)
                    case .slideHorizontal(let fromLeftToRight):
                        cycleSlideHorizontalFromViewController(from: old, to: new, fromLeftToRight: fromLeftToRight, withDuration: 0.6)
                    }
                    
                    
                }else{
                    
                    removeInactiveViewController(oldValue)
                    updateActiveViewController(activeViewController)
                }
                
            }
            
            animatedFlag = false
            
            
        }
    }
    
    
    override public var preferredStatusBarStyle : UIStatusBarStyle {
        
        return activeViewController?.preferredStatusBarStyle ?? .default
        
    }
    
    override public var childForStatusBarHidden : UIViewController? {
        
        return activeViewController
    }
    
    override public var childForStatusBarStyle : UIViewController? {
        
        return activeViewController
    }
    
    override public func viewWillLayoutSubviews() {
        
        if let activeVC = activeViewController {
            activeVC.view.frame = activeViewControllerContainerView.bounds
        }
    }
    
    
    
    
}


fileprivate extension PledgViewController{
    
     func removeInactiveViewController(_ inactiveViewController: UIViewController?) {
        if let inActiveVC = inactiveViewController {
            // call before removing child view controller's view from hierarchy
            inActiveVC.willMove(toParent: nil)
            
            inActiveVC.view.removeFromSuperview()
            
            // call after removing child view controller's view from hierarchy
            inActiveVC.removeFromParent()
        }
    }
    
    
     func updateActiveViewController(_ activeViewController: UIViewController?) {
        
        if let activeVC = activeViewController {
            
            
            addChild(activeVC)
            
            activeVC.view.autoresizingMask = [UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleTopMargin, .flexibleWidth, .flexibleHeight]
            
            
            activeVC.view.alpha = 1
            activeVC.view.frame = activeViewControllerContainerView.bounds
            activeViewControllerContainerView.addSubview(activeVC.view)
            
            activeVC.didMove(toParent: self)
        }
    }
    
    
    
    // animation
    
    
     func cycleFromViewController(from oldViewController:UIViewController, to newViewContoller:UIViewController){
        
        oldViewController.willMove(toParent: nil)
        
        
        addChild(newViewContoller)
        
        newViewContoller.view.autoresizingMask = [UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        
        newViewContoller.view.frame = activeViewControllerContainerView.bounds
        
        newViewContoller.view.alpha = 0
        
        activeViewControllerContainerView.addSubview(newViewContoller.view)
        
        UIView.animate(withDuration: 0.3, animations: {
            
            newViewContoller.view.alpha = 1;
            oldViewController.view.alpha = 0;
            
        }, completion: {_ in
            
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
            
            newViewContoller.didMove(toParent: self)
        })
    }
    
    
     func cycleSlideVerticalFromViewController(from oldViewController:UIViewController, to newViewContoller:UIViewController, fromTopToBottom:Bool, withDuration:TimeInterval = 0.3){
        
        oldViewController.willMove(toParent: nil)
        
        
        addChild(newViewContoller)
        
        newViewContoller.view.autoresizingMask = [UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        
        
        if fromTopToBottom {
            
            var frame = activeViewControllerContainerView.bounds
            frame.origin.y = -frame.size.height
            newViewContoller.view.frame = frame
            
        }else{
            var frame = activeViewControllerContainerView.bounds
            frame.origin.y = frame.size.height
            newViewContoller.view.frame = frame
        }
        
        
        newViewContoller.view.alpha = 0
        
        activeViewControllerContainerView.addSubview(newViewContoller.view)
        
        UIView.animate(withDuration: withDuration, animations: {
            
            newViewContoller.view.frame = self.activeViewControllerContainerView.bounds
            
            if fromTopToBottom {
                var frame = self.activeViewControllerContainerView.bounds
                frame.origin.y = frame.size.height
                oldViewController.view.frame = frame
                
            }else{
                var frame = self.activeViewControllerContainerView.bounds
                frame.origin.y = -frame.size.height
                oldViewController.view.frame = frame
            }
            
            newViewContoller.view.alpha = 1;
            oldViewController.view.alpha = 0;
            
        }, completion: {_ in
            
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
            
            newViewContoller.didMove(toParent: self)
        })
    }
    
    
     func cycleSlideHorizontalFromViewController(from oldViewController:UIViewController, to newViewContoller:UIViewController, fromLeftToRight:Bool, withDuration:TimeInterval = 0.3){
        
        oldViewController.willMove(toParent: nil)
        
        
        addChild(newViewContoller)
        
        newViewContoller.view.autoresizingMask = [UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        
        
        if fromLeftToRight {
            
            var frame = activeViewControllerContainerView.bounds
            frame.origin.x = -frame.size.width
            newViewContoller.view.frame = frame
            
        }else{
            var frame = activeViewControllerContainerView.bounds
            frame.origin.x = frame.size.width
            newViewContoller.view.frame = frame
        }
        
        
        newViewContoller.view.alpha = 0
        
        activeViewControllerContainerView.addSubview(newViewContoller.view)
        
        UIView.animate(withDuration: withDuration, animations: {
            
            newViewContoller.view.frame = self.activeViewControllerContainerView.bounds
            
            if fromLeftToRight {
                var frame = self.activeViewControllerContainerView.bounds
                frame.origin.x = frame.size.width
                oldViewController.view.frame = frame
                
            }else{
                var frame = self.activeViewControllerContainerView.bounds
                frame.origin.x = -frame.size.width
                oldViewController.view.frame = frame
            }
            
            newViewContoller.view.alpha = 1;
            oldViewController.view.alpha = 0;
            
        }, completion: {_ in
            
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
            
            newViewContoller.didMove(toParent: self)
        })
    }
}

fileprivate final class PledgeTransitionDelegate:NSObject,UIViewControllerTransitioningDelegate,UIAdaptivePresentationControllerDelegate{
    
    final class PledgPresentationController: UIPresentationController {
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?{
        
        let controller =  UIPresentationController(presentedViewController: presented, presenting: presenting)
        controller.delegate = self
        
        return controller
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return nil
    }
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return nil
        
    }
    
    
    //-------------
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        
        return .overFullScreen
        
    }
    
    public func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController?{
        
        return nil
    }
    
    public func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?){
        
    }
    
}

