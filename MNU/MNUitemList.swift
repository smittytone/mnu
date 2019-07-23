
//  ItemList.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class MNUitemList: NSObject {

    // NOTE This very simple class is used solely to allow us to pass
    //      the item list around by reference. The property 'items' is never
    //      nil - at minimum it is an empty array
    
    var items: [MNUitem] = []

}
