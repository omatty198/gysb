//
//  Interpreter.swift
//  GysbMacroLib
//
//  Created by omochimetaru on 2017/11/10.
//

import Foundation
import GysbBase

public class Interpreter {
    public init(source: String) {
        self.source = source
    }
    
    public func run() throws {
        let parser = Parser(tokenReader: TokenReader(source: source))
        
        for exp in try parser.parse() {
            try eval(exp)
        }
    }
    
    public var functions: [String: ([Any]) throws -> Any] = [:]
    
    public func registerFunction<A0, R>(name: String, fn: @escaping (A0) throws -> R) {
        functions[name] = { (args: [Any]) throws -> Any in
            guard args.count == 1 else {
                throw Error(message: "wrong arg num")
            }
            let arg0 = try cast(args[0], to: A0.self)
            let ret: R = try fn(arg0)
            return ret as Any
        }
    }
    
    @discardableResult
    private func eval(_ node: ASTNode) throws -> Any {
        switch node.switcher {
        case .call(let call):
            guard let fn = functions[call.name] else {
                throw Error(message: "undefined function: \(call.name)")
            }
            
            let args: [Any] = try call.args.map { (arg: AnyASTNode) -> Any in
                try eval(arg)
            }
            return try fn(args)
        case .stringLiteral(let str):
            return str.string
        }
    }
    
    private let source: String
}
