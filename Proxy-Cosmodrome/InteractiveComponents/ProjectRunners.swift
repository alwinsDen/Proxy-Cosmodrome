//
//  ProjectRunners.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 12/05/26.
//
import SwiftUI

struct ProjectRunners : View {
    var body : some View {
        HStack {
            Button{}label: {
                Image(systemName: "play.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Button{}label: {
                Image(systemName: "newspaper.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Button{}label: {
                Image(systemName: "eye.slash.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
