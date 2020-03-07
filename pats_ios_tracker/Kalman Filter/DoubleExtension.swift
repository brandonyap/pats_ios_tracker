//
//  DoubleExtension.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-03-07.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import Foundation

// MARK: Double as Kalman input
extension Double: KalmanInput {
    public var transposed: Double {
        return self
    }
    
    public var inversed: Double {
        return 1 / self
    }
    
    public var additionToUnit: Double {
        return 1 - self
    }
}
