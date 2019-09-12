//
//  Logger.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

private let loggingQueue = DispatchQueue(label: "shared.logger")

enum Logger {
    
    static func info(_ message: String, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        log(symbol: "📣", message: message, file: file, line: line, column: column, function: function)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        log(symbol: "⚠️", message: message, file: file, line: line, column: column, function: function)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        log(symbol: "❗️", message: message, file: file, line: line, column: column, function: function)
    }
    
    private static func log(symbol: String, message: String, file: String, line: Int, column: Int, function: String){
        loggingQueue.async {
            print("\(symbol) [\(filename(from: file)):\(function):\(line):\(column)]: \(message)")
        }
    }
    
}

private func filename(from fileString: String) -> String {
    return String(fileString.split(separator: "/").last ?? "")
}
