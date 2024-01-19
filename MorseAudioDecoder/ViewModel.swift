//
//  ViewModel.swift
//  MorseAudioDecoder
//
//  Created by Александр Говорухин on 19.01.2024.
//

import Foundation
import Combine

final class ViewModel: ObservableObject {
    
    @Published var morseCode: String = ""
    @Published var decodeText: String = ""
    
    @Published var isPressing: Bool = false
    
    let audioRecorder = AudioRecorder.shared
    let decodeMorse = DecodeMorseCode.shared
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        subscribe()
    }
    
    func subscribe() {
        
        $isPressing
            .dropFirst()
            .sink { [weak self] isPressing in
                isPressing
                    ? self?.audioRecorder.startRecording()
                    : self?.audioRecorder.stopRecording()
            }
            .store(in: &cancellables)
        
        audioRecorder.url
            .sink { [weak self] url in
                self?.decodeMorse.decode(url: url)
            }
            .store(in: &cancellables)
        
        decodeMorse.morseCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
                self?.morseCode = code
            }
            .store(in: &cancellables)
        
        decodeMorse.decodeText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.decodeText = text
            }
            .store(in: &cancellables)
    }
    
}
