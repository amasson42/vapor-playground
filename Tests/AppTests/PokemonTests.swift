@testable import App
import XCTVapor

import SQLKit

final class PokemonTests: XCTestCase {
    
    var app: Application!
    let pokemonsURI = "/api/v1/pokemons/"
    
    let existingPokemons = [
        "pikachu",
        "snorlax"
    ]
    
    let unexistingPokemons = [
        "caillou",
        "tintin"
    ]
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    
    func testPokemonsCanBeRetrievedFromAPI() throws {
        
        var pokemons: [Pokemon] = []
        for pokemonName in existingPokemons {
            try pokemons.append(App.Pokemon.create(name: pokemonName, on: app.db))
        }
        
        try app.test(.GET, pokemonsURI, afterResponse: { response in
            let recievedPokemons = try response.content.decode([App.Pokemon].self)
            XCTAssertEqual(recievedPokemons.count, existingPokemons.count)
            
            for (index, pokemon) in recievedPokemons.enumerated() {
                XCTAssertEqual(recievedPokemons[index].name, pokemon.name)
                XCTAssertEqual(recievedPokemons[index].id, pokemon.id)
            }
        })
    }
    
    func testPokemonCanBeSavedWithAPI() throws {
        
        for (index, pokemonName) in existingPokemons.enumerated() {
            let pokemon = Pokemon(name: pokemonName)
            
            try app.test(
                .POST, pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    let receivedPokemon = try response.content.decode(App.Pokemon.self)
                    XCTAssertEqual(receivedPokemon.name, pokemon.name)
                    XCTAssertNotNil(receivedPokemon.id)
                    
                    try app.test(
                        .GET, pokemonsURI,
                        afterResponse: { response in
                            let pokemons = try response.content.decode([App.Pokemon].self)
                            XCTAssertEqual(pokemons.count, index + 1)
                            XCTAssertEqual(pokemons[index].name, receivedPokemon.name)
                            XCTAssertEqual(pokemons[index].id, receivedPokemon.id)
                        })
                })
            
        }
    }
    
    func testGettingASinglePokemonFromTheAPI() throws {
        
        for pokemonName in existingPokemons {
            let pokemon = try App.Pokemon.create(name: pokemonName, on: app.db)
            
            try app.test(
                .GET, "\(pokemonsURI)\(pokemon.id!)",
                loggedInRequest: true,
                afterResponse: { response in
                    let returnedPokemon = try response.content.decode(App.Pokemon.self)
                    XCTAssertEqual(returnedPokemon.name, pokemon.name)
                    XCTAssertEqual(returnedPokemon.id, pokemon.id)
                })
        }
        
    }
    
    func testPostInvalidPokemonsFromTheAPI() throws  {
        
        for pokemonName in unexistingPokemons {
            
            let pokemon = Pokemon(name: pokemonName)
            
            try app.test(
                .POST, pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    XCTAssertEqual(response.status, .badRequest)
                })
        }
        
    }
    
    func testTwiceSameValidPokemonFromTheAPI() throws  {
        
        for pokemonName in existingPokemons {
            let pokemon = Pokemon(name: pokemonName)
            
            try app.test(
                .POST, pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    XCTAssertEqual(response.status, .ok)
                })
            
            try app.test(
                .POST, pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    XCTAssertEqual(response.status, .badRequest)
                })
        }
        
    }
    
    func testValidPokemonCachedFromTheAPI() throws {
        
        for pokemonName in existingPokemons {
            var pokemon = Pokemon(name: pokemonName)
            
            var startTime = Date()
            try self.app.test(
                .POST, self.pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    XCTAssertEqual(response.status, .ok)
                    pokemon = try response.content.decode(App.Pokemon.self)
                    XCTAssertNotNil(pokemon.id)
                })
            let firstPostTime = Date().timeIntervalSince(startTime)
            print("FirstPostTime: \(firstPostTime)")
            
            try pokemon.delete(on: app.db).wait()
            
            startTime = Date()
            try self.app.test(
                .POST, self.pokemonsURI,
                loggedInRequest: true,
                beforeRequest: { request in
                    try request.content.encode(pokemon)
                }, afterResponse: { response in
                    XCTAssertEqual(response.status, .ok)
                    pokemon = try response.content.decode(App.Pokemon.self)
                    XCTAssertNotNil(pokemon.id)
                })
            let secondPostTime = Date().timeIntervalSince(startTime)
            print("SecondPostTime: \(secondPostTime)")
            
            // TODO: Find a real way to check efficiency of caching
            // XCTAssertLessThan(secondPostTime, firstPostTime)
            
            print("Post Times Ratio: \(secondPostTime / firstPostTime)")
            
        }
        
    }
    
}
