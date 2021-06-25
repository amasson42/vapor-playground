import Vapor
import Fluent

struct PokemonsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("pokemons")
        group.get(use: handleGet)
        group.get(":pokemonID", use: handleGetOne)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: handlePost)
    }
    
    func handleGet(_ req: Request) -> EventLoopFuture<[Pokemon]> {
        return Pokemon.query(on: req.db).all()
    }
    
    func handleGetOne(_ req: Request) -> EventLoopFuture<Pokemon> {
        return Pokemon.find(req.parameters.get("pokemonID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func handlePost(_ req: Request) throws -> EventLoopFuture<Pokemon> {
        let newPokemon = try req.content.decode(Pokemon.self)
        
        return Pokemon.query(on: req.db)
            .filter(\.$name == newPokemon.name).count()
            .flatMapThrowing { count in
                guard count == 0 else {
                    throw Abort(.badRequest, reason: "You already caught \(newPokemon.name).")
                }
            }.flatMap { _ in
                return req.pokeAPI.verify(name: newPokemon.name)
            }.flatMap { nameVerified in
                guard nameVerified else {
                    return req.eventLoop.makeFailedFuture(
                        Abort(.badRequest, reason: "Invalid Pokemon \(newPokemon.name)."))
                }
                return newPokemon.save(on: req.db)
                    .transform(to: newPokemon)
            }
    }
    
}

extension Request {
    public var pokeAPI: PokeAPI {
        .init(client: self.client, cache: self.cache)
    }
}

/// A simple wrapper around the "pokeapi.co" API.
public final class PokeAPI {
    /// The HTTP client powering this API.
    let client: Client
    let cache: Cache
    
    /// Creates a new `PokeAPI` wrapper from the supplied client and cache.
    init(client: Client, cache: Cache) {
        self.client = client
        self.cache = cache
    }
    
    /// Returns `true` if the supplied Pokemon name is real.
    ///
    /// - parameter name: The name to verify.
    public func uncachedVerify(name: String) -> EventLoopFuture<Bool> {
        /// Query the PokeAPI.
        return fetchPokemon(named: name).flatMapThrowing { res in
            switch res.status.code {
            case 200..<300:
                /// The API returned 2xx which means this is a real Pokemon name
                return true
            case 404:
                /// The API returned a 404 meaning this Pokemon name was not found.
                return false
            default:
                /// The API returned a 500. Only thing we can do is forward the error.
                throw Abort(.internalServerError, reason: "Unexpected PokeAPI response: \(res.status)")
            }
        }
    }
    
    public func verify(name: String) -> EventLoopFuture<Bool> {
        let name = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cache.get(name, as: Bool.self).flatMap { verified in
            if let verified = verified {
                return self.client.eventLoop.makeSucceededFuture(verified)
            } else {
                return self.uncachedVerify(name: name)
                    .flatMap { verified in
                        return self.cache.set(name, to: verified)
                            .transform(to: verified)
                    }
            }
        }
    }
    
    /// Fetches a pokemen with the supplied name from the PokeAPI.
    private func fetchPokemon(named name: String) -> EventLoopFuture<ClientResponse> {
        let name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return client.get("https://pokeapi.co/api/v2/pokemon/\(name)")
    }
}
