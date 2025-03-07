//
//  KeyboardResponder.swift
//  CRM
//
//  Created by Michal Ziobro on 29/11/2019.
//  Copyright © 2019 Click 5 Interactive. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

public final class KeyboardAvoider : ObservableObject {
    
    private var _rects = [Int: CGRect]() {
        didSet {
            debugPrint("Keyboard Avoider rects changed: \(_rects.count)")
        }
    }
    public var rects: [Int: CGRect] {
        set {
            guard keyboardRect == .zero else {
                debugPrint("Warning: Keyboard Avoider changing rects while keyboard is visible.")
                return
            }
            _rects = newValue
        }
        get {
            _rects
        }
    }
    
    public var editingField : Int = -1 {
        didSet {
            updateSlideSize()
        }
    }
    
    // MARK: - Publishers
    public var slideSizePublisher = CurrentValueSubject<CGSize, Never>(.zero)
    
    // MARK: - Observable interface
    @Published public var slideSize: CGSize = .zero
    @Published public var isInitialized: Bool = false
    
    @Published public var keyboardRect: CGRect = .zero {
        didSet {
            updateSlideSize()
        }
    }
    //private var isKeyboardHidden: Bool = true
    
    private var keyboardWillShow : Cancellable? = nil
    private var keyboardWillHide : Cancellable? = nil
    
    public init() {
        debugPrint("Keyboard Avoider init")
        
        self.keyboardWillShow = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map { (notification) -> CGRect in
            self.isInitialized = true
            if let rect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
                return rect
            } else {
                return .zero
            }
        }
        .receive(on: RunLoop.main)
        .assign(to: \.keyboardRect, on: self)
        
        self.keyboardWillHide = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map {_ -> CGRect in .zero }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
        .assign(to: \.keyboardRect, on: self)
    }
    
    deinit {
        debugPrint("Keyboard Avoider deinit")
        
        self.keyboardWillShow?.cancel()
        self.keyboardWillHide?.cancel()
    }
    
    private func updateSlideSize() {
        
        guard let fieldRect = self.rects[editingField] else {
            slideSize = .zero
            slideSizePublisher.send(.zero)
            return
        }
        
        guard keyboardRect != .zero else {
            slideSize = .zero
            slideSizePublisher.send(.zero)
            return
        }
        
        let diff = fieldRect.maxY - keyboardRect.minY + 48
    
        if keyboardRect.minY < fieldRect.maxY + 48 {
             slideSize = CGSize(width: 0, height: -diff)
             slideSizePublisher.send(CGSize(width: 0, height: -diff))
        } else {
            slideSize = .zero
            slideSizePublisher.send(.zero)
        }
    }
  
}

public extension KeyboardAvoider {
    
    public func keyboardOffsets(isTabBar: Bool = true, offset: CGFloat = 0) -> (total: CGFloat, adjusted: CGFloat) {
        
        let tabBarHeight = isTabBar ? UITabBarController().tabBar.frame.height : 0
        let safeAreaHeight = UIApplication.shared.windows.first{ $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
        let totalKeyboardOffset = self.keyboardRect.height
        let keyboardOffset = totalKeyboardOffset > 0 ? totalKeyboardOffset - tabBarHeight - safeAreaHeight - offset : 0
        
        return (totalKeyboardOffset, keyboardOffset)
    }
}

public extension List {
    
    func attachKeyboardAvoider(_ keyboardAvoider: KeyboardAvoider, offset: CGFloat = 0) -> some View {
    
        let (total, adjusted) = keyboardAvoider.keyboardOffsets(offset: offset)
        
       return self
        .padding(.bottom, total > 0 ? adjusted + 32 : 0)
    }
    
    func attachKeyboardAvoiderPublisher(_ keyboardAvoider: KeyboardAvoider, offset: CGFloat = 0) -> some View {
        
        return self.modifier(AttachedKeyboardAvoider(keyboardAvoider, offset: offset))
    }
}


public struct AttachedKeyboardAvoider : ViewModifier {
    
    @State public var total : CGFloat = 0
    @State public var adjusted : CGFloat = 0
    
    public let avoider: KeyboardAvoider
    public let offset: CGFloat
    
    public init(_ avoider: KeyboardAvoider, offset: CGFloat = 0) {
        self.avoider = avoider
        self.offset = offset
    }
    
    public func body(content: Content) -> some View {
        
        content
        .padding(.bottom, total > 0 ? adjusted + 32 : 0)
        .onReceive(avoider.slideSizePublisher) { size in
            
            let (total, adjusted) = self.avoider.keyboardOffsets(offset: self.offset)
            debugPrint("Total: \(total), adjusted: \(adjusted) keyboard bottom padding.")
            DispatchQueue.main.async {
                self.total = total
                self.adjusted = adjusted
            }
        }
    }
}

public extension ScrollView {
    
    public func attachKeyboardAvoider(_ keyboardAvoider: KeyboardAvoider, offset: CGFloat = 0) -> some View {
    
        let (total, adjusted) = keyboardAvoider.keyboardOffsets(offset: offset)
        
       return self
        .padding(.bottom, total > 0 ? adjusted + 32 : 0)
    }
    
    public func attachKeyboardAvoiderPublisher(_ keyboardAvoider: KeyboardAvoider, offset: CGFloat = 0) -> some View {
        
        return self.modifier(AttachedKeyboardAvoider(keyboardAvoider, offset: offset))
    }
}
