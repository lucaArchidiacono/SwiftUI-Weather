//
//  LoadingIndicator.swift
//  SwiftUI-Weather
//
//  Created by Luca Archidiacono on 01.11.21.
//

import SwiftUI

struct LoadingIndicator: Shape {
  var percent: Double
  
  func path(in rect: CGRect) -> Path {
    let end = percent * 360
    var p = Path()

    p.addArc(center: CGPoint(x: rect.size.width/2, y: rect.size.width/2),
             radius: rect.size.width/2,
             startAngle: Angle(degrees: 0),
             endAngle: Angle(degrees: end),
             clockwise: false)
    
    return p
  }
    
  var animatableData: Double {
    get { return percent }
    set { percent = newValue }
  }
}
