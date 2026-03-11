// SuperSetsWidgetBundle.swift
// Super Sets — Widget Extension
//
// Entry point for the widget extension. Currently only contains
// the Live Activity — can be extended with home screen widgets later.

import SwiftUI
import WidgetKit

@main
struct SuperSetsWidgetBundle: WidgetBundle {
    var body: some Widget {
        SuperSetsLiveActivity()
    }
}
