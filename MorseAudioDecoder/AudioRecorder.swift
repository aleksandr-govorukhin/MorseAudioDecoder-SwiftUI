//
//  AudioRecorder.swift
//  MorseAudioDecoder
//
//  Created by Александр Говорухин on 19.01.2024.
//

import Foundation
import AVFAudio
import Combine

final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    static var shared = AudioRecorder()
    
    var url = PassthroughSubject<URL, Never>()
    var audioRecorder: AVAudioRecorder?
    
    override init() {
        super.init()
        initialization()
    }
    
    func startRecording() {
        audioRecorder?.record()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    // AVAudioRecorderDelegate method
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            url.send(recorder.url)
            print("Audio file URL: \(recorder.url)")
        } else {
            print("Recording failed.")
        }
    }
}

private extension AudioRecorder {
    func initialization() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recordedAudio.wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44800,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            print("Error setting up audio session or initializing recorder: \(error.localizedDescription)")
        }
    }
}
