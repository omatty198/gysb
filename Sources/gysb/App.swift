//
//  App.swift
//  gysb
//
//  Created by omochimetaru on 2017/11/07.
//

import Foundation

class App {
    enum Mode {
        case help
        case parse
        case macro
        case compile
        case render
    }
    
    struct Option {
        var mode: Mode
        var path: String?
    }
    
    func main() -> Int32 {
        do {
            return try _main()
        } catch let e {
            print("[Error] \(e)")
            return EXIT_FAILURE
        }
    }
    
    func _main() throws -> Int32 {
        let option: Option
        do {
            option = try parseCommandLine(args: CommandLine.arguments)
        } catch let e {
            print("[Error] \(e)")
            print()
            printHelp()
            return EXIT_FAILURE
        }
        
        if option.mode == .help {
            printHelp()
            return EXIT_SUCCESS
        }
        
        let path = option.path!
        
        let source = try String(contentsOfFile: path, encoding: .utf8)
        
        var template = try Parser.init(source: source).parse()
        if option.mode == .parse {
            template.print()
            return EXIT_SUCCESS
        }
        
        template = try MacroExecutor.init(template: template, path: path).execute()
        if option.mode == .macro {
            template.print()
            return EXIT_SUCCESS
        }
        
        let code = CodeGenerator.init(template: template).generate()
        if option.mode == .compile {
            print(code)
            return EXIT_SUCCESS
        }
        
        guard option.mode == .render else {
            throw Error(message: "invalid mode running")
        }
        try CodeExecutor(code: code, path: path).execute()
        
        return EXIT_SUCCESS
    }
    
    private func parseCommandLine(args: [String]) throws -> Option {
        var index = 1
        
        if index >= args.count {
            throw Error(message: "invalid args")
        }

        let mode: Mode
        var path: String? = nil
        
        var arg = args[index]
        index += 1
        
        switch arg {
        case "--help":
            mode = .help
        case "--parse":
            mode = .parse
        case "--macro":
            mode = .macro
        case "--compile":
            mode = .compile
        case "--render":
            mode = .render
        default:
            index -= 1
            mode = .render
        }
        
        switch mode {
        case .help:
            break
        default:
            if index >= args.count {
                throw Error(message: "path not specified")
            }
            arg = args[index]
            index += 1
            
            path = arg
        }
        
        return Option(mode: mode, path: path)
    }
    
    private func printHelp() {
        let text = """
        Usage: \(CommandLine.arguments[0]) [mode] path
        
        # mode
            --help: print help
            --parse: print AST
            --macro: print macro evaluated AST
            --compile: print compiled Swift
            --render: render template
        """
        print(text)
    }
}
