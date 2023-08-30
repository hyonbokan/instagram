//
//  Extensions.swift
//  Instagram
//
//  Created by dnlab on 2023/08/16.
//

import Foundation
import UIKit

extension UIView {
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var bottom: CGFloat {
        return frame.origin.y + frame.size.height
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.origin.x + frame.size.width
    }
}

extension String {
     func safeDatabaseKey() -> String {
          return self.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
    }
}

// Check this Decodable
extension Decodable {
    init?(with dictionary: [String: Any]) {
        guard let data = try? JSONSerialization.data(
            withJSONObject: dictionary,
            options: .prettyPrinted
        ) else {
            return nil
        }
                
        guard let result = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = result
    }
}

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let json = try? JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any]
        return json
    }
}
