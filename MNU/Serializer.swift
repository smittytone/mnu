
/*
   Serializer.swift
   MNU

   Created by Tony Smith on 01/10/2019.
   Copyright © 2019-20 Tony Smith. All rights reserved.

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

        // Generate a simple JSON serialization of the specified Menu Item object

        // TODO Fix for escapable characters

        var json = "{\"title\":\"\(item.title)\",\"type\":\(item.type),"
        json += "\"code\":\(item.code),\"icon\":\(item.iconIndex),"
        json += "\"script\":\"\(item.script)\",\"hidden\":\(item.isHidden),"
        json += "\"direct\":\(item.isDirect)}"
        return json
    }
    
    
    static func jsonizeAll(_ list: MenuItemList) -> String {
            
        // Generatae a full JSON string containing the full list of menu items
        // The top level object, 'data', is an array of all of the Menu Item
        // JSON strings
        var jsonString: String = "{\"data\":["
        var count: Int = 0
        
        for item: MenuItem in list.items {
            jsonString += Serializer.jsonize(item)
            count += 1
            if count < list.items.count {
                jsonString += ","
            }
        }
        
        jsonString += "]}"
        return jsonString
    }


    static func dejsonize(_ json: String) -> MenuItem? {

        // Recreate a Menu Item object from our simple JSON serialization and return it,
        // or nil to indicate failure

        // Convert JSON string to data
        if let data = json.data(using: .utf8) {
            do {
                let dict: [String: Any] = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                return makeNewItem(dict)
            } catch {
                NSLog("Error in Serializer.dejsonize(): \(error.localizedDescription)")
            }
        }

        // Failure condition
        return nil
    }


    static func dejsonizeAll(_ jsonData: Data) -> MenuItemList? {

        // Unpack a full JSON file - ie. a menu list archive and return it,
        // or nil to indicate failure
        
        // First, create a new menu
        let newMenu: MenuItemList = MenuItemList()

        do {
            // Convert the JSON data to a dictionary, and get the 'data' key's array value
            let dict: [String: Any] = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            if let dataItems = dict["data"] {
                // Run through the array's elements, converting each to a MenuItem
                let items: [Any] = dataItems as! [Any]

                for item: Any in items {
                    let srcItem: [String:Any] = item as! [String:Any]
                    newMenu.items.append(makeNewItem(srcItem))
                }

                // Finally, return the new MenuItemList
                return newMenu
            } else {
                // Error reading expected JSON condition
                NSLog("Error in Serializer.dejsonizeAll(): No 'data' field")
                return nil
            }
        } catch {
            NSLog("Error in Serializer.dejsonizeAll(): \(error.localizedDescription)")
        }

        // Failure condition
        return nil
    }


    static private func makeNewItem(_ dict: [String:Any]) -> MenuItem {

        // Generate and return a Mene Item from a dictionary, providing
        // default values in the case of missing fields
        let newItem = MenuItem()
        let iconIndex = dict["icon"] as? Int
        newItem.iconIndex = iconIndex != nil ? iconIndex! : 0
        newItem.title = dict["title"] as? String ?? "Unknown"
        newItem.script = dict["script"] as? String ?? ""
        newItem.type = dict["type"] as? Int ?? 1
        newItem.code = dict["code"] as? Int ?? 20
        newItem.isHidden = dict["hidden"] as? Bool ?? false
        newItem.isDirect = dict["direct"] as? Bool ?? false
        return newItem
    }
}
