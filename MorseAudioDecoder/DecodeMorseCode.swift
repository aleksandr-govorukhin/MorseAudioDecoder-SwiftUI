//
//  DecodeMorseCode.swift
//  MorseAudioDecoder
//
//  Created by Александр Говорухин on 19.01.2024.
//

import Foundation
import AVFAudio
import Combine

final class DecodeMorseCode {
    
    static let shared = DecodeMorseCode()
    
    let morseDict: [String: String] = [
        ".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
        "--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
        "--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
        "...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
        "-.--": "Y", "--..": "Z",
        ".----": "1", "..---": "2", "...--": "3", "....-": "4", ".....": "5",
        "-....": "6", "--...": "7", "---..": "8", "----.": "9", "-----": "0",
        ".-.-.-": ".", "---...": ":", "--..--": ",", "-.-.-.": ";", "..--..": "?",
        "-...-": "=", ".----.": "'", "-..-.": "/", "-.-.--": "!", "-....-": "-",
        "..--.-": "_", ".-..-.": "\"", "-.--.": "(", "-.--.-": ")", "...-..-": "$",
        ".-...": "&", ".--.-.": "@"
    ]
    
    private var audioEngine = AVAudioEngine()
    
    var morseCode = PassthroughSubject<String, Never>()
    var decodeText = PassthroughSubject<String, Never>()
    
    init() {
        setupAudioEngine()
    }
    
    func startAudioEngine() {
        do {
            try audioEngine.start()
            print("Audio Engine Started")
        } catch {
            print("Error starting Audio Engine: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        print("Audio Engine Stopped")
    }
    
    func decode(url: URL) {
        // Указать полный путь к аудиофайлу
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return
        }
        
        let audioFormat = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        
        do {
            try audioFile.read(into: buffer, frameCount: frameCount)
        } catch {
            print("Error reading audio file: \(error)")
        }
        
        // Чтение аудио информации
        let frames = Int(frameCount)
        
        // Чтение информации о спектре
        let waveData = buffer.floatChannelData!.pointee
        let waveAvg = Int(waveData.pointee / Float(frames))
        
        // Рисование графика Морзе
        var morseBlockSum = 0
        var morseBlockLength = 0
        var morseArr = [Int]()
        var timeArr = [Int]()
        
        for i in 0..<frames {
            let value = Int(abs(waveData[i]) * 10)
            
            if value > waveAvg {
                morseBlockSum += 1
            } else {
                morseBlockSum += 0
            }
            
            morseBlockLength += 1
            
            if morseBlockLength == 100 {
                // Если среднее значение блока больше половины, считаем его как "1", иначе "0"
                if sqrt(Float(morseBlockSum) / 100) > 0.5 {
                    morseArr.append(1)
                } else {
                    morseArr.append(0)
                }
                
                timeArr.append(timeArr.count)
                morseBlockLength = 0
                morseBlockSum = 0
            }
        }
        
        // Преобразование в код Морзе
        var morseType = [Int]()
        var morseLen = [Int]()
        var morseObjSum = [0, 0]
        var morseObjLen = [0, 0]
        
        for i in morseArr {
            // Если массив пуст или последний элемент не совпадает с текущим, начинаем новый блок
            if morseType.isEmpty || morseType.last! != i {
                morseObjLen[i] += 1
                morseObjSum[i] += 1
                morseType.append(i)
                morseLen.append(1)
            } else {
                // Если длина блока не превышает 100, увеличиваем его длину
                if morseLen.last! <= 100 {
                    morseObjSum[i] += 1
                    morseLen[morseType.count - 1] += 1
                }
            }
        }
        
        let morseBlockAvg = Float(morseObjSum[1]) / Float(morseObjLen[1])
        print("morse block avg: \(morseBlockAvg)")
        let morseBlankAvg = Float(morseObjSum[0]) / Float(morseObjLen[0])
        print("morse blank avg: \(morseBlankAvg)")
        
        // Конвертация в код Морзе
        var morseResult = ""
        for i in 0..<morseType.count {
            if morseType[i] == 1 {
                // Если длина блока больше средней, считаем его как "-", иначе "."
                if morseLen[i] > Int(morseBlockAvg) {
                    morseResult += "-"
                } else if morseLen[i] < Int(morseBlockAvg) {
                    morseResult += "."
                }
            } else if morseType[i] == 0 {
                if morseLen[i] > Int(morseBlankAvg) {
                    print(morseLen[i])
                    print(morseBlankAvg)
                    morseResult += "/"
                }
            }
        }
        
        self.morseCode.send(morseResult)
        
        // Декодирование кода Морзе
        let morseArray = morseResult.components(separatedBy: "/")
        var plainText = ""
        
        for morse in morseArray {
            if let morse = morseDict[morse] {
                plainText += morse
            }
        }
        
        self.decodeText.send(plainText)
    }
}

private extension DecodeMorseCode {
    func setupAudioEngine() {
        
        // Установка формата аудио (может потребоваться настройка в соответствии с вашими требованиями)
        let audioInputNode = audioEngine.inputNode
        
        // Создание узла ввода для записи аудио
        let format = audioEngine.inputNode.inputFormat(forBus: 0)
        
        var morseResult = ""
        
        // Добавление обработчика блока для аудиоузла
        audioInputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            
            // Чтение аудио информации
            let frames = Int(buffer.frameLength)
            
            // Чтение информации о спектре
            let waveData = buffer.floatChannelData!.pointee
            let waveAvg = Int(waveData.pointee / Float(frames))
            
            // Рисование графика Морзе
            var morseBlockSum = 0
            var morseBlockLength = 0
            var morseArr = [Int]()
            var timeArr = [Int]()
            
            for i in 0..<frames {
                let value = Int(abs(waveData[i]) * 10)
                
                if value > waveAvg {
                    morseBlockSum += 1
                } else {
                    morseBlockSum += 0
                }
                
                morseBlockLength += 1
                
                if morseBlockLength == 100 {
                    // Если среднее значение блока больше половины, считаем его как "1", иначе "0"
                    if sqrt(Float(morseBlockSum) / 100) > 0.6 {
                        morseArr.append(1)
                    } else {
                        morseArr.append(0)
                    }
                    
                    timeArr.append(timeArr.count)
                    morseBlockLength = 0
                    morseBlockSum = 0
                }
            }
            
            // Преобразование в код Морзе
            var morseType = [Int]()
            var morseLen = [Int]()
            var morseObjSum = [0, 0]
            var morseObjLen = [0, 0]
            
            for i in morseArr {
                // Если массив пуст или последний элемент не совпадает с текущим, начинаем новый блок
                if morseType.isEmpty || morseType.last! != i {
                    morseObjLen[i] += 1
                    morseObjSum[i] += 1
                    morseType.append(i)
                    morseLen.append(1)
                } else {
                    // Если длина блока не превышает 100, увеличиваем его длину
                    if morseLen.last! <= 100 {
                        morseObjSum[i] += 1
                        morseLen[morseType.count - 1] += 1
                    }
                }
            }
            
            let morseBlockAvg = Float(morseObjSum[1]) / Float(morseObjLen[1])
            let morseBlankAvg = Float(morseObjSum[0]) / Float(morseObjLen[0])
            
            // Конвертация в код Морзе
            for i in 0..<morseType.count {
                if morseType[i] == 1 {
                    // Если длина блока больше средней, считаем его как "-", иначе "."
                    if morseLen[i] > Int(morseBlockAvg) {
                        morseResult += "-"
                    } else if morseLen[i] < Int(morseBlockAvg) {
                        morseResult += "."
                    }
                } else if morseType[i] == 0 {
                    if morseLen[i] > Int(morseBlankAvg) {
                        morseResult += "/"
                    }
                }
            }
        }
        
        audioEngine.prepare()
    }
}
