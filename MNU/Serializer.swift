/*
    Serializer.swift
    MNU

    Created by Tony Smith on 01/10/2019.
    Copyright © 2026 Tony Smith. All rights reserved.

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

    enum error: Error {
        case BadSingleSerialization
        case BadGroupSerialization
        case BadSingleDeserialization
        case BadGroupDeserialization
    }


    /**
     Generate a simple JSON serialization of the specified Menu Item object.

     - Parameters:
        - item: The MenuItem instance to process.

     - Returns: The MenuItem data as a JSON string.
     */
    static func jsonize(_ item: MenuItem) -> String {

        var json = ""
        let dict = dictionise(item)

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.sortedKeys)
            json = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            NSLog("Menu item \(item.title) could not be serialized")
        }

        return json
    }


    /**
     Generatae a full JSON string containing the full list of menu items
     The top level object, 'data', is an array of all of the Menu Item
     JSON strings.

     - Parameters:
        - list: The MenuItemList to process.

     - Returns: The MenuItemList data as a JSON string.
     */
    static func jsonizeAll(_ list: MenuItemList) -> String {
            
        var jsonString = ""
        var dict: [String:[[String:Any]]] = [:]
        dict["data"] = [[String:Any]]()

        for item in list.items {
            let itemDict = dictionise(item)
            dict["data"]?.append(itemDict)
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.sortedKeys)
            jsonString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            NSLog("Could not serialize MNU items")
        }

        return jsonString
    }


    /**
     Convert a single MenuItem into a dictionary.

     - Parameters:
        - item: The MenuItem to process.

     - Returns: A dictionary of `String` keys and `Any` values.
     */
    private static func dictionise(_ item: MenuItem) -> [String:Any] {

        var dict: [String:Any] = [:]
        dict["title"] = item.title
        dict["type"] = item.type.rawValue
        dict["code"] = item.code
        dict["icon"] = item.iconIndex
        dict["script"] = item.script
        dict["hidden"] = item.isHidden
        // FROM 1.2.2
        dict["direct"] = item.isDirect
        // FROM 1.7.0
        dict["keyequivalent"] = item.keyEquivalent
        dict["keymodflags"] = item.keyModFlags
        dict["uuid"] = item.uuid
        // FROM 2.0.0
        dict["image"] = item.customImageId
        dict["output"] = item.showDirectOutput
        return dict
    }


    /**
     Recreate a Menu Item object from our simple JSON serialization and return it,
     or `nil` to indicate failure.

     - Parameters:
        - json: The JSON string to decode.

     - Returns: A MenuItem instance or `nil` on error.
     */
    static func dejsonize(_ json: String) -> MenuItem? {

        // Convert JSON string to data
        if let data = json.data(using: .utf8) {
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                return makeNewItem(dict)
            } catch {
                NSLog("Error in Serializer.dejsonize(): \(error.localizedDescription)")
            }
        }

        // Failure condition
        return nil
    }


    /**
     Unpack a full JSON file - ie. a menu list archive and return it,
     or `nil` to indicate failure

     - Parameters:
        - json: The JSON (as raw data) to decode.

     - Returns: A MenuItemList instance or `nil` on error.
     */
    static func dejsonizeAll(_ json: Data) -> MenuItemList? {

        // First, create a new menu
        let newMenu: MenuItemList = MenuItemList()

        do {
            // Convert the JSON data to a dictionary, and get the 'data' key's array value
            let dict = try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
            if let dataItems = dict["data"] {
                // Run through the array's elements, converting each to a MenuItem
                let items: [Any] = dataItems as! [Any]

                for item in items {
                    let srcItem = item as! [String:Any]
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


    /**
     Generate and return a Mene Item from a dictionary, providing
     default values in the case of missing fields.

     - Parameters:
        - dict: A dictionory of keys and values from JSON.

     - Returns: A MenuItem object.
     */
    static private func makeNewItem(_ dict: [String:Any]) -> MenuItem {

        //

        let newItem = MenuItem()
        let iconIndex = dict["icon"] as? Int
        newItem.iconIndex = iconIndex != nil ? iconIndex! : 0
        newItem.title = dict["title"] as? String ?? "Unknown"
        newItem.script = dict["script"] as? String ?? ""
        newItem.type = MNUItemType(rawValue: (dict["type"] as? Int ?? -1)) ?? .unknown
        newItem.code = dict["code"] as? Int ?? 20
        newItem.isHidden = dict["hidden"] as? Bool ?? false
        // FROM 1.2.2
        newItem.isDirect = dict["direct"] as? Bool ?? false
        // FROM 1.7.0
        newItem.keyEquivalent = dict["keyequivalent"] as? String ?? ""
        newItem.keyModFlags = dict["keymodflags"] as? UInt ?? 0
        newItem.uuid = dict["uuid"] as? String ?? UUID().uuidString
        // FROM 2.0.0
        newItem.customImageId = dict["image"] as? String ?? ""
        newItem.showDirectOutput = dict["output"] as? Bool ?? false
        return newItem
    }
    
}
