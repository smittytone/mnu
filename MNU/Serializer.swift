
/*
   Serializer.swift
   MNU

   Created by Tony Smith on 01/10/2019..
   Copyright © 2019 Tony Smith. All rights reserved.

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


import Foundation


struct Serializer {
    
    static func jsonize(_ item: MenuItem) -> String {

        // Generate a simple JSON string serialization of the specified Menu Item object
        var json = "{\"title\": \"\(item.title)\",\"type\": \(item.type),"
        json += "\"code\":\(item.code),\"icon\":\(item.iconIndex),"
        json += "\"script\":\"\(item.script)\",\"hidden\": \(item.isHidden)}"
        return json
    }


    static func dejsonize(_ json: String) -> MenuItem? {

        // Recreate a Menu Item object from our simple JSON serialization
        // NOTE We still need to create 'controller' properties, and this is done later
        //      See 'updateMenu()'
        if let data = json.data(using: .utf8) {
            do {
                let dict: [String: Any]? = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let newItem = MenuItem()
                newItem.title = dict!["title"] as! String
                newItem.script = dict!["script"] as! String
                newItem.type = dict!["type"] as! Int
                newItem.code = dict!["code"] as! Int
                newItem.isHidden = dict!["hidden"] as! Bool

                // New items
                let iconIndex = dict!["icon"] as? Int
                newItem.iconIndex = iconIndex != nil ? iconIndex! : 0
                return newItem
            } catch {
                NSLog("Error in Serializer.dejsonize(): \(error.localizedDescription)")
            }
        }

        return nil
    }
}
