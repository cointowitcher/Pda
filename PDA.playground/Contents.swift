import UIKit

enum PdaState: CustomStringConvertible, Hashable {
    var description: String {
        switch self {
        case .A: return "<A>"
        case .D: return "<D>"
        case .B: return "<B>"
        case .E: return "<E>"
        case .C: return "<C>"
        }
    }
    
    // States
    case A
    case D
    case B
    case E
    case C
}

enum Input: String, Hashable {
    case a
    case b
    case c
    case minus = "-"
    case asterisk = "*"
    case leftBracket = "("
    case rightBracket = ")"
    case dollar = "$"
}

enum StateSymbol: CustomStringConvertible {
    case terminal(Input)
    case state(PdaState)
    case empty
    
    var description: String {
        switch self {
        case let .terminal(s): return s.rawValue
        case let .state(state): return "\(state)"
        case .empty: return ""
        }
    }
}

struct PdaStateInput: Hashable {
    var ps: PdaState
    var inp: Input
    init(_ ps: PdaState, _ inp: Input) {
        self.ps = ps
        self.inp = inp
    }
}


let mTable: [PdaStateInput: [StateSymbol]] = [
    .init(.A, .a): [.state(.B), .state(.D)],
    .init(.A, .b): [.state(.B), .state(.D)],
    .init(.A, .c): [.state(.B), .state(.D)],
    .init(.B, .a): [.state(.C), .state(.E)],
    .init(.B, .b): [.state(.C), .state(.E)],
    .init(.B, .c): [.state(.C), .state(.E)],
    .init(.C, .a): [.terminal(.a)],
    .init(.C, .b): [.terminal(.b)],
    .init(.C, .c): [.terminal(.c)],
    .init(.D, .minus): [.terminal(.minus), .state(.B), .state(.D)],
    .init(.E, .minus): [.empty],
    .init(.E, .asterisk): [.terminal(.asterisk), .state(.C), .state(.E)],
    .init(.A, .leftBracket): [.state(.B), .state(.D)],
    .init(.B, .leftBracket): [.state(.C), .state(.E)],
    .init(.C, .leftBracket): [.terminal(.leftBracket), .state(.A), .terminal(.rightBracket)],
    .init(.D, .rightBracket): [.empty],
    .init(.E, .rightBracket): [.empty],
    .init(.D, .dollar): [.empty],
    .init(.E, .dollar): [.empty]
//    .init(.E, .a): [.state(.T), .state(.E2)],
//    .init(.E, .b): [.state(.T), .state(.E2)],
//    .init(.E, .c): [.state(.T), .state(.E2)],
//    .init(.E, .leftBracket): [.state(.T), .state(.E2)],
//
//    .init(.E2, .plus): [.terminal(.plus), .state(.T), .state(.E2)],
//    .init(.E2, .rightBracket): [.empty],
//    .init(.E2, .dollar): [.empty],
//
//    .init(.T, .a): [.state(.F), .state(.T2)],
//    .init(.T, .b): [.state(.F), .state(.T2)],
//    .init(.T, .c): [.state(.F), .state(.T2)],
//    .init(.T, .leftBracket): [.state(.F), .state(.T2)],
//
//    .init(.T2, .plus): [.empty],
//    .init(.T2, .asterisk): [.terminal(.asterisk), .state(.F), .state(.T2)],
//    .init(.T2, .rightBracket): [.empty],
//    .init(.T2, .dollar): [.empty],
//
//    .init(.F, .a): [.terminal(.a)],
//    .init(.F, .b): [.terminal(.b)],
//    .init(.F, .c): [.terminal(.c)],
//    .init(.F, .leftBracket): [.terminal(.leftBracket), .state(.E), .terminal(.rightBracket)]
]

struct StringError: Error, LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

public extension String {
    func paddedToWidth(_ width: Int) -> String {
        let length = self.count
        guard length < width else {
            return self
        }

        let spaces = Array<Character>.init(repeating: " ", count: width - length)
        return self + spaces
    }
}

class Pda {
    private var stack = [StateSymbol]()
    private var currentString: String
    
    private func translate(_ state: PdaState) throws -> [StateSymbol] {
        guard let input = Input(rawValue: String(currentString.first!)),
              let symbols = mTable[.init(state, input)] else { throw StringError(message: "No match \(state) to \(currentString.first!)") }
        return symbols
    }
    
    init(_ string: String) {
        self.currentString = string
    }
    
    func analyze() throws {
        stack.append(.terminal(.dollar))
        stack.append(.state(.A))
        log()
        try recursive()
    }
        
    private func recursive() throws {
        guard !currentString.isEmpty else { return }
        guard let popped = stack.popLast() else { return }
        switch popped {
        case let .state(state):
            var symbols: [StateSymbol] = (try translate(state)).reversed()
            stack.append(contentsOf: symbols)
            log()
        case let .terminal(terminal):
            guard Input(rawValue: String(currentString.first!))! == terminal else { throw StringError(message: "Should be \(terminal) got \(currentString.first!)") }
            currentString = String(currentString[currentString.index(currentString.startIndex, offsetBy: 1)...])
            log()
        case .empty: break
        }
        try recursive()
    }
    
    private func log() {
        print("\("\(stack.reduce(into: "") { $0 += "\($1)" })".paddedToWidth(20)) \t \(currentString)")
    }
}

let pda = Pda("(a-b)*c$")
do {
    try pda.analyze()
} catch {
    print("ERROR: " + error.localizedDescription)
}
