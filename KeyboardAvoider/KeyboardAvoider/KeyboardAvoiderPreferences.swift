//
//  KeyboardAvoidingPreference.swift
//  CRM
//
//  Created by Michal Ziobro on 29/11/2019.
//  Copyright © 2019 Click 5 Interactive. All rights reserved.
//

import SwiftUI

// MARK: - Keyboard Avoiding Field Preference
public struct KeyboardAvoiderPreference: Equatable {
    
    public let tag: Int
    public let rect: CGRect
    
    public static func == (lhs: KeyboardAvoiderPreference, rhs: KeyboardAvoiderPreference) -> Bool {
        debugPrint("y: \(lhs.rect.minY) vs \(rhs.rect.minY)")
       return  lhs.tag == rhs.tag && (lhs.rect.minY == rhs.rect.minY)
    }
}

public struct KeyboardAvoiderPreferenceKey: PreferenceKey {
    
    public typealias Value = [KeyboardAvoiderPreference]
    
    public static var defaultValue: [KeyboardAvoiderPreference] = []
    
    public static func reduce(value: inout [KeyboardAvoiderPreference], nextValue: () -> [KeyboardAvoiderPreference]) {
         value.append(contentsOf: nextValue())
    }
}


public struct KeyboardAvoiderPreferenceReader: ViewModifier {
    
    public let tag: Int
    
    public func body(content: Content) -> some View {
        
        content
            .background(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .preference(
                            key: KeyboardAvoiderPreferenceKey.self,
                            value: [
                                KeyboardAvoiderPreference(tag: self.tag, rect: geometry.frame(in: .global))
                        ])
                }
            )
    }
}

public extension View {
    
    public func avoidKeyboard(tag: Int) -> some View {
        self.modifier(KeyboardAvoiderPreferenceReader(tag: tag))
    }
    
    /* deprecated - change to view modifier struct
    func avoidKeyboard(tag: Int) -> some View {
        
        self.background(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .preference(
                            key: KeyboardAvoiderPreferenceKey.self,
                            value: [
                                KeyboardAvoiderPreference(tag: tag, rect: geometry.frame(in: .global))
                        ])
                }
        )
    }
    */
}
