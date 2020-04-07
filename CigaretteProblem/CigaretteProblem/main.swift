//
//  main.swift
//  CigaretteProblem
//
//  Created by Vlad Nechiporenko on 4/7/20.
//  Copyright © 2020 Vlad Nechyporenko. All rights reserved.
//

import Foundation

class Dealer {
    var dealer: DispatchSemaphore
    var table: Table
    
    init(table: Table, dealer: DispatchSemaphore){
        self.dealer = dealer
        self.table = table
    }
    
    func run(){
        dealer.wait()
        provideIngredients()
    }
    
    func provideIngredients(){
        let temp = Int.random(in: 0...2)
        if temp == 0{
            print("Dealer puts paper and matches on the table")
            table.putPaper()
            table.putMatches()
        }
        if temp == 1{
            print("Dealer puts pushing tobacco and matches on the table")
            table.putTobacco()
            table.putMatches()
        }
        if temp == 2{
            print("Dealer puts pushing tobacco and paper on the table")
            table.putTobacco()
            table.putPaper()
        }
    }
}

class Smoker{
    var smoker: DispatchSemaphore
    var dealer: DispatchSemaphore
    var smokerType: String
    
    init(smoker: DispatchSemaphore, dealer: DispatchSemaphore, smokerType: String){
        self.smoker = smoker
        self.dealer = dealer
        self.smokerType = smokerType
    }
    
    func run(){
        smoker.wait()
        makeCigarette()
        dealer.signal()
        smokeCigarette()
    }
    
    func makeCigarette(){
        print(smokerType + " is making cigarette")
        sleep(2)
        print(smokerType + " has completed to make cigarette - Table is clean now")
    }
    
    func smokeCigarette(){
        print(smokerType + " is smoking now")
        sleep(5)
        print(smokerType + " has finished smoking the cigarette")
    }
}

class Table {
    let tobaccoSem = DispatchSemaphore(value: 0)
    let paperSem = DispatchSemaphore(value: 0)
    let matchSem = DispatchSemaphore(value: 0)
    var smokerWithTobaccoSem: DispatchSemaphore
    var smokerWithPaperSem: DispatchSemaphore
    var smokerWithMatchesSem: DispatchSemaphore
    var isTobacco = false
    var isPaper = false
    var isMatch = false
    let queue4 = DispatchQueue(label: "Table.queue4")
    let queue1 = DispatchQueue(label: "Table.queue1")
    let queue2 = DispatchQueue(label: "Table.queue2")
    let queue3 = DispatchQueue(label: "Table.queue3")
    
    init(smokerWithTobaccoSem: DispatchSemaphore, smokerWithPaperSem: DispatchSemaphore, smokerWithMatchesSem: DispatchSemaphore){
        self.smokerWithTobaccoSem = smokerWithTobaccoSem
        self.smokerWithPaperSem = smokerWithPaperSem
        self.smokerWithMatchesSem = smokerWithMatchesSem
        
        initWorkers()
    }
    
    func putTobacco() {
        tobaccoSem.signal()
    }

    func putPaper() {
        paperSem.signal()
    }

    func putMatches() {
        matchSem.signal()
    }
    
    func initWorkers(){
        queue1.async {
            while(true){
                self.tobaccoSem.wait()
                self.queue4.sync{
                    if self.isPaper {
                        self.isPaper = false
                        self.smokerWithMatchesSem.signal()
                    } else if (self.isMatch) {
                        self.isMatch = false
                        self.smokerWithPaperSem.signal()
                    } else {
                        self.isTobacco = true
                    }
                }
            }
        }
        queue2.async {
            while(true){
                self.paperSem.wait()
                self.queue4.sync{
                    if self.isTobacco {
                        self.isTobacco = false
                        self.smokerWithMatchesSem.signal()
                    } else if (self.isMatch) {
                        self.isMatch = false
                        self.smokerWithTobaccoSem.signal()
                    } else {
                        self.isPaper = true
                    }
                }
            }
        }
        queue3.async {
            while(true){
                self.matchSem.wait()
                self.queue4.sync{
                    if self.isPaper {
                        self.isPaper = false
                        self.smokerWithTobaccoSem.signal()
                    } else if (self.isTobacco) {
                        self.isTobacco = false
                        self.smokerWithPaperSem.signal()
                    } else {
                        self.isMatch = true
                    }
                }
            }
        }
    }
}



let dealerSem = DispatchSemaphore(value: 1)
let smokerWithTobaccoSem = DispatchSemaphore(value: 0)
let smokerWithPaperSem = DispatchSemaphore(value: 0)
let smokerWithMatchesSem = DispatchSemaphore(value: 0)
let queue4 = DispatchQueue(label: "queue4")
let queue1 = DispatchQueue(label: "queue1")
let queue2 = DispatchQueue(label: "queue2")
let queue3 = DispatchQueue(label: "queue3")


let table = Table(smokerWithTobaccoSem: smokerWithTobaccoSem, smokerWithPaperSem: smokerWithPaperSem, smokerWithMatchesSem: smokerWithMatchesSem)
let dealer = Dealer(table: table, dealer: dealerSem)
let smoker1 = Smoker(smoker: smokerWithTobaccoSem, dealer: dealerSem, smokerType: "SmokerWithTobacco")
let smoker2 = Smoker(smoker: smokerWithPaperSem, dealer: dealerSem, smokerType: "SmokerWithPaper")
let smoker3 = Smoker(smoker: smokerWithMatchesSem, dealer: dealerSem, smokerType: "SmokerWithMatches")

while(true){
    queue4.async {
        dealer.run()
    }
    queue1.async {
        smoker1.run()
    }
    queue2.async {
        smoker2.run()
    }
    queue3.async {
        smoker3.run()
    }
}

