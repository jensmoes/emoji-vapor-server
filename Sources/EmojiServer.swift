import Foundation
import Vapor
import OpenAPIRuntime
import OpenAPIVapor

actor EmojiServiceAPIHandler: APIProtocol {

    let logger: Logger = Logger(label: "EmojiService")
    private var emojis: Set<Item>

    init(default: String = "🐱😍🍎") async {
        emojis = `default`.reduce(into: Set()) { partialResult, char in
            if char.isEmoji {
                partialResult.insert(Item(emoji: char))
            }
        }
    }
    
    func setEmoji(_ input: Operations.setEmoji.Input) async throws -> Operations.setEmoji.Output {
        let requestBody : Components.Schemas.Emoji
        switch input.body {
        case .json(let json): requestBody = json
        }

        if requestBody.emoji.isEmpty {
            let e = Components.Schemas.SubmitError(code: ._0, description: "No emoji :(")
            logger.debug("\(e.description)")
            let response = Operations.setEmoji.Output.BadRequest(body: .json(e))
            return .badRequest(response)
        }
        
        logger.debug("Received an emoji \(requestBody.emoji) from \(requestBody.source)")
        
        if requestBody.emoji.count > 1 {
            let e = Components.Schemas.SubmitError(code: ._2, description: "Data contains more than one emoji. You may only submit one at a time")
            logger.debug("\(e.description)")
            return .badRequest(Operations.setEmoji.Output.BadRequest.init(body: .json(e)))
        }
        
        
        let newChar = Character(requestBody.emoji)
        let newItem = Item(emoji: newChar, author: requestBody.source)

        if !newChar.isEmoji {
            let e = Components.Schemas.SubmitError(code: ._3, description: "Submitted character is not an emoji")
            logger.debug("\(e.description)")
            return .badRequest(Operations.setEmoji.Output.BadRequest.init(body: .json(e)))
        }
        
        let result = emojis.insert(newItem)
        if !result.inserted {
            let e = Components.Schemas.SubmitError(code: ._1, description: "This is already here. It was submitted by \(result.memberAfterInsert.author)")
            logger.debug("\(e.description)")
            let response = Operations.setEmoji.Output.BadRequest(body: .json(e))
            return .badRequest(response)

        }
        logger.debug("Remembering \(newItem). Thank you \(requestBody.source)!")
        return .created(Operations.setEmoji.Output.Created())
    }
    
    func getEmoji(_ input: Operations.getEmoji.Input) async throws -> Operations.getEmoji.Output {
        guard let pick = emojis.randomElement() else {
            let e = Components.Schemas.SubmitError(code: ._0, description: "No emojis on server :(")
            logger.debug("\(e.description)")
            let response = Operations.getEmoji.Output.BadRequest(body: .json(e))
            return .badRequest(response)
        }
        let output = Operations.getEmoji.Output.Ok(body: .json(pick.asSchema))
        return .ok(output)
    }
    
    
}

private struct Item: Hashable, Equatable {
    
    internal init(emoji: Character, author: String = "System") {
        self.emoji = emoji
        self.author = author
    }
    
    let emoji: Character
    let author: String
    
    // Below is a custom hash and equatable implementation
    // We use this to only discriminate on the emoji character in our set
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(emoji)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.emoji == rhs.emoji
    }
}

extension Item {
    var asSchema: Components.Schemas.Emoji {
        Components.Schemas.Emoji(emoji: String(emoji), source: author)
    }
}

fileprivate extension Character {
    /// `true` is all the scalars composing the character
    var isEmoji: Bool {
        unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji
            && scalar.properties.isEmojiPresentation
        }
    }
}

@main
struct EmojiVaporServer {
    static func main() async throws {
        let app = try await Vapor.Application.make()

        let transport = VaporTransport(routesBuilder: app)

        let handler = await EmojiServiceAPIHandler()

        try handler.registerHandlers(on: transport, serverURL: Servers.server1())

        try await app.execute()

    }
}


