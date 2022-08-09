//
//  PreferencesView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI

struct PreferencesView: View {
    @State var userName = "Незнакомец"
    
    var body: some View {
        VStack {
            Text("Привет, \(userName)!")
            Text("День вашей зарплаты: \(salaryDay)")
        }
        .onAppear {
            let name = NSUserName()
            if name != "" {
                userName = name
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
