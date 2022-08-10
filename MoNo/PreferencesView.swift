//
//  PreferencesView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI

struct PreferencesView: View {
    @State var userName = "Пользователь"
    @State var isActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Привет, \(userName)!")
                Text("День вашей зарплаты: \(salaryDay)")
//                NavigationLink("", isActive: $isActive) {
//                    EditView(userName: $userName)
//                }
            }
            .navigationTitle("Профиль")
            .fullScreenCover(isPresented: $isActive) {
                EditView(userName: $userName)
            }
            .toolbar {
                Button {
                    isActive.toggle()
                } label: {
                    Text("Изменить")
                }
            }
        }
    }
}
