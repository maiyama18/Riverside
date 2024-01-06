//
//  ActionViewController.swift
//  RiversideIOSActionExtension
//
//  Created by maiyama18 on 2024/01/05
//  
//

import IOSActionExtension
import MobileCoreServices
import UIKit

final class ActionViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        let contentViewController = ActionController(context: extensionContext!)
        addChild(contentViewController)
        contentViewController.didMove(toParent: self)
        
        contentView.addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor),
        ])
    }

    @IBAction func done() {
        self.extensionContext!.completeRequest(
            returningItems: self.extensionContext!.inputItems,
            completionHandler: nil
        )
    }
}
