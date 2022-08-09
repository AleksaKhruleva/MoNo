//
//  PreferencesView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI

struct PreferencesView: View {
    @State var userName = "Пользователь"
    
    var body: some View {
        VStack {
            Text("Привет, \(userName)!")
            Text("День вашей зарплаты: \(salaryDay)")
        }
    }
}
