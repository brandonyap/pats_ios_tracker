//
//  BeaconLocationStore.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-02-05.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import SwiftUI
import Combine

class BeaconLocationStore : ObservableObject {
    @Published var beacons: [BeaconLocationModel]
    
    init (beacons: [BeaconLocationModel] = []) {
        self.beacons = beacons
    }
}
