//
//  ViewController.swift
//  MudMapViewer
//
//  Created by Wil Hunt on 11/13/15.
//  Copyright © 2015 William Hunt. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    /* Swift */
    @IBAction func unwindToMainMenu(_ sender: NSStoryboardSegue)
    {
        // let sourceViewController = sender.sourceController
        // Pull any data from the view controller which initiated the unwind segue.
    }

}

