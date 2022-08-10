//
//  EditView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 10.08.2022.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var userName: String
    
    var body: some View {
        VStack {
            Button("Done") {
                dismiss()
            }
            TextField("Введите имя", text: $userName)
                .padding()
        }
    }
}
