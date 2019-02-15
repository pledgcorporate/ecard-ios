//
//  PledgeWebViewController.swift
//  Alamofire
//
//  Created by Lukasz Zajdel on 16/11/2018.
//

import Foundation
import WebKit
import SafariServices




internal class PledgeWebViewController: UIViewController {
    
    var settings:TransactionConfiguration!

    var didReceiveEventHandler:((ApiEventRootResponse,PledgeWebViewController)->Void)? = nil
    
    var webKitErrorHandler:((Error,PledgeWebViewController)->Void)? = nil
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let contentController = WKUserContentController()
        
        let eventNames = [PledgSettings.jsCompletionHandlerName]
        
        for eventname in eventNames {
            contentController.add(self, name: eventname)
        }
        
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(
            frame: self.view.bounds,
            configuration: config
        )
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[webView]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["webView": webView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["webView": webView]))
        
        
        webView.allowsBackForwardNavigationGestures = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        //webView.uiDelegate = self
        webView.navigationDelegate = self
        
        
        self.webView = webView
        
        self.setupProgressView()
        self.setupEstimatedProgressObserver()
        self.setupActivityIndicatorView()
        
        self.setProgressHidden(hidden: true, animated: false)
        
        let url = settings.url
        
        debugLog("Load url:\(url)")
        
        webView.load(URLRequest(url: url))
    }
    
    
    public func reload(){
        
        if !isViewLoaded{
            return
        }
        
        let url = settings.url
        
        debugLog("Reload url:\(url)")
        
        webView.load(URLRequest(url: url))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupEstimatedProgressObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        invalidateEstimatedProgressObserver()
        
    }
    
    func evaluateJavaScriptCancel(completion:(()->Void)? = nil){
        
        completion?()
        
        /*
        let js = PledgSettings.jsCancelMethodName
        
        webView.evaluateJavaScript(js) { ifno, error in
            self.debugLog("Cancel ifno:\(String(describing: ifno)) error:\(String(describing: error))")
            completion?()
        }
        */
    }
    
    
    let progressView = UIProgressView(progressViewStyle: .default)
    
    let activityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    private func setupEstimatedProgressObserver() {
        
        progressView.progress = Float(webView.estimatedProgress)
        
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }
    private func invalidateEstimatedProgressObserver() {
        
        estimatedProgressObserver?.invalidate()
        estimatedProgressObserver = nil
    }
    
    
    private func setupActivityIndicatorView(){
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.isHidden = true
        
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
    }
    
    

    private func setupProgressView() {
       
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(progressView)
        
        progressView.isHidden = true
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 2.0)
                ])
        } else {
            NSLayoutConstraint.activate([
                progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                progressView.topAnchor.constraint(equalTo: view.topAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 2.0)
                ])
            
        }
    }
    
    fileprivate func debugLog( _ message:String){
        
        print("PLEDG: \(message)")
    }
    
}




extension PledgeWebViewController:WKScriptMessageHandler{
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        debugLog("[WKScriptMessageHandler] userContentController:didReceive message name:\(message.name) body:\(message.body)")
        
        do {
            
            let decoder = JSONDecoder()
            
            let data = try JSONSerialization.data(withJSONObject: message.body, options: [])
            
            let reponse = try decoder.decode(ApiEventRootResponse.self, from: data)
           
            self.didReceiveEventHandler?(reponse,self)
            
        } catch let error{
            
            debugLog("Parse event error:\(error)")
            
            //self.webKitErrorHandler?(error,self)
            
            
        }
        
        
    }
}

extension WKNavigationType{
    func debugString()->String{
        switch self {
        case .backForward:
            return "backForward"
        case .linkActivated:
            return "linkActivated"
        case .formSubmitted:
            return "formSubmitted"
        case .reload:
            return "reload"
        case .formResubmitted:
            return "formResubmitted"
        case .other:
            return "other"
        }
    }
}

extension PledgeWebViewController:WKNavigationDelegate{
    
    /*! @abstract Invoked when a main frame navigation starts.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    
    
    func setProgressHidden(hidden:Bool, animated:Bool){
        
        debugLog("setProgressHidden navigation:\(hidden)")
        
        if animated{
            UIView.animate(withDuration: 0.33) {
                self.progressView.isHidden = hidden
                self.activityIndicatorView.isHidden = hidden
            }
        }else{
            self.progressView.isHidden = hidden
            self.activityIndicatorView.isHidden = hidden
        }
        
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        
        debugLog("[WKNavigationDelegate] webView:didStartProvisionalNavigation navigation:\(String(describing: navigation))")
        
        setProgressHidden(hidden: false, animated: true)
        
    }
    
    /*! @abstract Invoked when a main frame navigation completes.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        
        debugLog("[WKNavigationDelegate] webView:didCommit navigation:\(String(describing: navigation)) ")
        
        setProgressHidden(hidden: true, animated: true)
        
    }
    
    
    
    /*! @abstract Invoked when an error occurs while starting to load data for
     the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error){
        
        
        debugLog("[WKNavigationDelegate] webView:didFailProvisionalNavigation navigation:\(String(describing: navigation)) withError:\(error)")
        
        webKitErrorHandler?(error,self)
        
        setProgressHidden(hidden: true, animated: true)
        
        
    }
    
    
    
   
    
    
    /*! @abstract Decides whether to allow or cancel a navigation.
     @param webView The web view invoking the delegate method.
     @param navigationAction Descriptive information about the action
     triggering the navigation request.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
     @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
     */
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void){
        
        
        if let path = navigationAction.request.url?.relativePath, path.contains("downloadCGU") && navigationAction.navigationType == .linkActivated{
            
            if let url = navigationAction.request.url {
                let safariVC = SFSafariViewController(url: url, entersReaderIfAvailable: true)
                self.present(safariVC, animated: true, completion: nil)
            }
            
            decisionHandler(.cancel)
            
            return
        }
        
        debugLog("[WKNavigationDelegate] webView:decidePolicyFor [navigationAction] type:\(navigationAction.navigationType.debugString()) request.url:\(String(describing: navigationAction.request.url))")
        
        decisionHandler(.allow)
        
    }
    
    
    /*! @abstract Decides whether to allow or cancel a navigation after its
     response is known.
     @param webView The web view invoking the delegate method.
     @param navigationResponse Descriptive information about the navigation
     response.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     @discussion If you do not implement this method, the web view will allow the response, if the web view can show it.
     */
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void){
        
        
        debugLog("[WKNavigationDelegate] webView:decidePolicyFor [navigationResponse] response.url:\(String(describing: navigationResponse.response.url))")
        
        decisionHandler(.allow)
        
    }
    
    
    
    
    
    /*! @abstract Invoked when a server redirect is received for the main
     frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!){
        
        
        //debugLog("[WKNavigationDelegate] webView:didReceiveServerRedirectForProvisionalNavigation navigation:\(String(describing: navigation))")
        
    }
    
    
 
    
    
    /*! @abstract Invoked when content starts arriving for the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!){
        
        //debugLog("[WKNavigationDelegate] webView:didCommit navigation:\(String(describing: navigation))")
    }
    
    
  
    
    /*! @abstract Invoked when an error occurs during a committed main frame
     navigation.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error){
        
        
        debugLog("[WKNavigationDelegate] webView:didFail navigation:\(String(describing: navigation)) withError:\(error)")
        
        webKitErrorHandler?(error,self)
    }
    
    
    /*! @abstract Invoked when the web view needs to respond to an authentication challenge.
     @param webView The web view that received the authentication challenge.
     @param challenge The authentication challenge.
     @param completionHandler The completion handler you must invoke to respond to the challenge. The
     disposition argument is one of the constants of the enumerated type
     NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
     the credential argument is the credential to use, or nil to indicate continuing without a
     credential.
     @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
     */
    /*
     func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
     
     
     debugLog("[WKNavigationDelegate] webView:didReceive challenge:\(challenge)")
     
     completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling,nil)
     }
     */
    
    /*! @abstract Invoked when the web view's web content process is terminated.
     @param webView The web view whose underlying web content process was terminated.
     */
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView){
        
        
        //debugLog("[WKNavigationDelegate] webViewWebContentProcessDidTerminate")
    }
}




extension PledgeWebViewController:WKUIDelegate{
    
    /*! @abstract Creates a new web view.
     @param webView The web view invoking the delegate method.
     @param configuration The configuration to use when creating the new web
     view.
     @param navigationAction The navigation action causing the new web view to
     be created.
     @param windowFeatures Window features requested by the webpage.
     @result A new web view or nil.
     @discussion The web view returned must be created with the specified configuration. WebKit will load the request in the returned web view.
     
     If you do not implement this method, the web view will cancel the navigation.
     */
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView?{
        
        debugLog("[WKUIDelegate] webView:createWebViewWith configuration:\(configuration) for navigationAction:\(navigationAction) windowFeatures:\(windowFeatures)")
        return nil
    }
    
    
    /*! @abstract Notifies your app that the DOM window object's close() method completed successfully.
     @param webView The web view invoking the delegate method.
     @discussion Your app should remove the web view from the view hierarchy and update
     the UI as needed, such as by closing the containing browser tab or window.
     */
    func webViewDidClose(_ webView: WKWebView){
        
        debugLog("[WKUIDelegate] webViewDidClose")
    }
    
    
    /*! @abstract Displays a JavaScript alert panel.
     @param webView The web view invoking the delegate method.
     @param message The message to display.
     @param frame Information about the frame whose JavaScript initiated this
     call.
     @param completionHandler The completion handler to call after the alert
     panel has been dismissed.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have a single OK button.
     
     If you do not implement this method, the web view will behave as if the user selected the OK button.
     */
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void){
        
        
        debugLog("[WKUIDelegate] webView:runJavaScriptAlertPanelWithMessage :\(message) initiatedByFrame:\(frame)")
        
        completionHandler()
        
    }
    
    
    /*! @abstract Displays a JavaScript confirm panel.
     @param webView The web view invoking the delegate method.
     @param message The message to display.
     @param frame Information about the frame whose JavaScript initiated this call.
     @param completionHandler The completion handler to call after the confirm
     panel has been dismissed. Pass YES if the user chose OK, NO if the user
     chose Cancel.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have two buttons, such as OK and Cancel.
     
     If you do not implement this method, the web view will behave as if the user selected the Cancel button.
     */
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void){
        
        debugLog("[WKUIDelegate] webView:runJavaScriptConfirmPanelWithMessage :\(message) initiatedByFrame:\(frame)")
        
        completionHandler(true)
    }
    
    
    /*! @abstract Displays a JavaScript text input panel.
     @param webView The web view invoking the delegate method.
     @param prompt The prompt to display.
     @param defaultText The initial text to display in the text entry field.
     @param frame Information about the frame whose JavaScript initiated this call.
     @param completionHandler The completion handler to call after the text
     input panel has been dismissed. Pass the entered text if the user chose
     OK, otherwise nil.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have two buttons, such as OK and Cancel, and a field in
     which to enter text.
     
     If you do not implement this method, the web view will behave as if the user selected the Cancel button.
     */
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void){
        
        
        debugLog("[WKUIDelegate] webView:runJavaScriptTextInputPanelWithPrompt :\(prompt) defaultText:\(String(describing: defaultText)) initiatedByFrame:\(frame)")
        completionHandler("Test")
    }
    
    
    /*! @abstract Allows your app to determine whether or not the given element should show a preview.
     @param webView The web view invoking the delegate method.
     @param elementInfo The elementInfo for the element the user has started touching.
     @discussion To disable previews entirely for the given element, return NO. Returning NO will prevent
     webView:previewingViewControllerForElement:defaultActions: and webView:commitPreviewingViewController:
     from being invoked.
     
     This method will only be invoked for elements that have default preview in WebKit, which is
     limited to links. In the future, it could be invoked for additional elements.
     */
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool{
        
        debugLog("[WKUIDelegate] webView:shouldPreviewElement elementInfo:\(elementInfo)")
        
        return true
    }
    
    
    /*! @abstract Allows your app to provide a custom view controller to show when the given element is peeked.
     @param webView The web view invoking the delegate method.
     @param elementInfo The elementInfo for the element the user is peeking.
     @param defaultActions An array of the actions that WebKit would use as previewActionItems for this element by
     default. These actions would be used if allowsLinkPreview is YES but these delegate methods have not been
     implemented, or if this delegate method returns nil.
     @discussion Returning a view controller will result in that view controller being displayed as a peek preview.
     To use the defaultActions, your app is responsible for returning whichever of those actions it wants in your
     view controller's implementation of -previewActionItems.
     
     Returning nil will result in WebKit's default preview behavior. webView:commitPreviewingViewController: will only be invoked
     if a non-nil view controller was returned.
     */
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController?{
        
        debugLog("[WKUIDelegate] webView:previewingViewControllerForElement elementInfo:\(elementInfo) defaultActions:\(previewActions)")
        
        return nil
    }
    
    
    /*! @abstract Allows your app to pop to the view controller it created.
     @param webView The web view invoking the delegate method.
     @param previewingViewController The view controller that is being popped.
     */
    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController){
        
        debugLog("[WKUIDelegate] webView:commitPreviewingViewController previewingViewController:\(previewingViewController) ")
        
    }
    
    
}
