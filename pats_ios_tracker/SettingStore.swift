//
//  SettingStore.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-02-05.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import SwiftUI
import Combine

class SettingStore : ObservableObject {
    @Published var url_address: String
    
    init () {
        self.url_address = UserDefaults.standard.string(forKey: "address") ?? "192.168.0.36:8888"
    }
}
