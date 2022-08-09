//
//  MainView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Меню", systemImage: "list.bullet")
                }
            
            PreferencesView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
