//
//  ContentView.swift
//  MorseAudioDecoder
//
//  Created by Александр Говорухин on 19.01.2024.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Код морзе:")
                Text(viewModel.morseCode)
            }
            VStack {
                Text("Декодированный текст:")
                Text(viewModel.decodeText)
            }
            Button {
                viewModel.isPressing.toggle()
            } label: {
                Text(
                    viewModel.isPressing
                        ? "Закончить запись"
                        : "Начать запись"
                )
            }
            .background(
                Circle()
                    .fill(
                        viewModel.isPressing ? Color.red : Color.gray
                    )
                    .padding()
            )
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
