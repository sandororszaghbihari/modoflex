//
//  WordPair.swift
//  modoflex
//
//  Created by Orszagh Bihari Sandor  on 2025. 07. 27..
//


import Foundation

struct WordPair: Identifiable {
    let id: Int
    let hungarian: String
    let spanish: String
    let questionNote: String
    let answerNote: String
    let score: String
    
    init(id: Int, hungarian: String, spanish: String, questionNote: String = "", answerNote: String = "", score: String = "0") {
        self.id = id
        self.hungarian = hungarian
        self.spanish = spanish
        self.questionNote = questionNote
        self.answerNote = answerNote
        self.score = score
    }
    
    init(hungarian: String, spanish: String) {
        self.id = 0
        self.hungarian = hungarian
        self.spanish = spanish
        self.questionNote = ""
        self.answerNote = ""
        self.score = "0"
    }
}