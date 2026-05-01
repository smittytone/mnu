//
//  PMTab.swift
//  MNU
//
//  Created by Tony Smith on 01/05/2026.
//  Copyright © 2026 Tony Smith. All rights reserved.
//

import Foundation


/*
 Structure to store four sizes required for a PMTab’s content.
 */
public struct ContentSize {

    private enum Size {
        case min
        case max
        case current
        case `default`
    }

    private var sizes: [Size: NSSize?] = [:]

    var minimum: NSSize? {
        get { return sizes[.min] ?? nil }
        set(new) { set(.min, new) }
    }

    var maximum: NSSize? {
        get { return sizes[.max] ?? nil }
        set(new) { set(.max, new) }
    }

    var current: NSSize? {
        get { return sizes[.current] ?? nil }
        set(new) { set(.current, new) }
    }

    var `default`: NSSize? {
        get { return sizes[.default] ?? nil }
        set(new) { set(.default, new) }
    }

    private mutating func set(_ kind: Size, _ value: NSSize?) {

        sizes[kind] = value
    }
}


/*
 A metadata storage class for the tabs managed by PMTabManger.
 */
final public class PMTab {

    // MARK: - Public Properties

    public var name: String? = nil                      // An optional identifier
    public var callback: (()->Void)? = nil              // An optional callback function triggered before the switch
    public var isResizeable: Bool = false               // Is the Tab resizeable? If it is not, you need only set the
                                                        // default content size -- this will be returned whatever size
                                                        // accessor is used. If the tab is resizeable, set either a
                                                        // minimum content size, a maximum one or both. Again, default
                                                        // is a proxy for unset values.


    // MARK: - Private Properties

    private var sizes: ContentSize = ContentSize()


    // MARK: - Accessors

    var minimumSize: NSSize? {
        get { if self.isResizeable { return self.sizes.minimum } else { return self.defaultSize } }
        set(new) { self.sizes.minimum = new }
    }

    var maximumSize: NSSize? {
        get { if self.isResizeable { return self.sizes.maximum } else { return self.defaultSize } }
        set(new) { self.sizes.maximum = new }
    }

    var currentSize: NSSize? {
        get { if self.isResizeable { return self.sizes.current } else { return self.defaultSize } }
        set(new) { self.sizes.current = new }
    }

    var defaultSize: NSSize? {
        get { return self.sizes.default ?? nil }
        set(new) { self.sizes.default = new }
    }


    // MARK: - Constructor

    init() {

        // Ensure the Tab's base size data is populated as this will be returned
        // in unset sizes are requested.
        defaultSize = NSSize(width: 640.0, height: 480.0)
    }
}
