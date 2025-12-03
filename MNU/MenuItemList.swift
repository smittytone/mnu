
/*
    MenuItemList.swift
    MNU

    Created by Tony Smith on 05/07/2019.
    Copyright © 2025 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
 */


import Cocoa


final class MenuItemList: NSObject,
                          NSCopying {

    // NOTE This very simple class is used solely to allow us to pass
    //      the item list around by reference. The property 'items' is never
    //      nil - at minimum it is an empty array
    
    var items: [MenuItem] = []
    
    
    /**
     Encode the instance to a JSON string for backup tasks.
     
     - Returns The list of menu items as a string, or a thrown error.
     */
    func encode() throws -> String {
        
        let result = Serializer.jsonizeAll(self)
        guard !result.isEmpty else { throw Serializer.error.BadGroupSerialization }
        return result
    }
    
    
    /**
     Create a new instance from JSON data.
     
     - Parameters
        - json: The data from which to decode to MenuItemList.
     
     - Returns The list of menu items, or a thrown error.
     */
    static func decode(_ json: Data) throws -> MenuItemList {
        
        let result = Serializer.dejsonizeAll(json)
        guard let realResult = result else { throw Serializer.error.BadGroupDeserialization }
        return realResult
    }


    func copy(with zone: NSZone? = nil) -> Any {

        let listCopy = MenuItemList()
        for item in self.items {
            listCopy.items.append(item)
        }

        return listCopy
    }
}
