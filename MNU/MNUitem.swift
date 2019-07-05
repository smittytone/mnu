
//  MNUitem.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class MNUitem: NSObject {

    // MARK: - Properties
    var title: String = ""
    var code: Int = -1
    var type: Int = -1
    var controller: Any? = nil
    var index: Int = -1

    
    // MARK: - Object Lifecycle Functions

    override init() {
        super.init()
    }
}
