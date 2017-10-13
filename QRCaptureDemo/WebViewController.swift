//
//  WebViewController.swift
//  QRCaptureDemo
//
//  Created by Nicolás Miari on 2017/10/13.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class WebViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView!

    var url: URL!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        /*
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
         */
        if let navigation = webView.load(URLRequest(url: url)) {
            print(navigation)
        }
    }
}
