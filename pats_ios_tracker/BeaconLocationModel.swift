//
//  BeaconLocationModel.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-02-05.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import SwiftUI

struct BeaconLocationModel: Codable, Identifiable {
    var id: Int
    var uuid: String
    var group_id: Int
    var beacons_id: Int
    var location_x: Float
    var location_y: Float
}

struct BeaconLocationListResponse: Codable {
    let success: Bool
    let data: [BeaconLocationModel]
}
