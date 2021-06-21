@testable import App
import XCTVapor

final class AcronymTests: XCTestCase {
    
    var app: Application!
    let acronymsURI = "/api/acronyms/"
    let acronymShort = "OMG"
    let acronymLong = "Oh My God"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testAcronymsCanBeRetrievedFromAPI() throws {
        let acronym0 = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronym1 = try Acronym.create(on: app.db)
        
        try app.test(.GET, acronymsURI, afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            
            XCTAssertEqual(acronyms[0].short, acronym0.short)
            XCTAssertEqual(acronyms[0].long, acronym0.long)
            XCTAssertEqual(acronyms[0].id, acronym0.id)
            
            XCTAssertEqual(acronyms[1].short, acronym1.short)
            XCTAssertEqual(acronyms[1].long, acronym1.long)
            XCTAssertEqual(acronyms[1].id, acronym1.id)
        })
    }
    
    func testAcronymCanBeSavedWithAPI() throws {
        let user = try User.create(on: app.db)
        
        let createAcronymData = CreateAcronymData(short: acronymShort, long: acronymLong)
        
        try app.test(
            .POST, acronymsURI,
            loggedInUser: user,
            beforeRequest: { request in
                try request.content.encode(createAcronymData)
            }, afterResponse: { response in
                let receivedAcronym = try response.content.decode(Acronym.self)
                XCTAssertEqual(receivedAcronym.short, acronymShort)
                XCTAssertEqual(receivedAcronym.long, acronymLong)
                XCTAssertNotNil(receivedAcronym.id)
                
                XCTAssertEqual(receivedAcronym.$user.id, user.id)
                
                try app.test(.GET, acronymsURI, afterResponse: { allAcronymsResponse in
                    let acronyms = try allAcronymsResponse.content.decode([Acronym].self)
                    XCTAssertEqual(acronyms.count, 1)
                    
                    if acronyms.count == 1 {
                        XCTAssertEqual(acronyms[0].short, acronymShort)
                        XCTAssertEqual(acronyms[0].long, acronymLong)
                        XCTAssertEqual(acronyms[0].id, receivedAcronym.id)
                        XCTAssertEqual(acronyms[0].$user.id, user.id)
                    }
                    
                })
            })
    }
    
    func testGettingASingleAcronymFromTheAPI() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)", afterResponse: { response in
            let returnedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(returnedAcronym.short, acronymShort)
            XCTAssertEqual(returnedAcronym.long, acronymLong)
            XCTAssertEqual(returnedAcronym.id, acronym.id)
        })
    }
    
    func testUpdatingAnAcronym() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let newUser = try User.create(on: app.db)
        let newLong = "Oh My Gosh"
        let updatedAcronymData = CreateAcronymData(short: acronymShort, long: newLong)
        
        try app.test(
            .PUT, "\(acronymsURI)\(acronym.id!)",
            loggedInUser: newUser,
            beforeRequest: { request in
            try request.content.encode(updatedAcronymData)
        })
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)", afterResponse: { response in
            let returnedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(returnedAcronym.short, acronymShort)
            XCTAssertEqual(returnedAcronym.long, newLong)
            XCTAssertEqual(returnedAcronym.$user.id, newUser.id)
        })
    }
    
    func testDeletingAnAcronym() throws {
        let acronym = try Acronym.create(on: app.db)
        
        try app.test(
            .GET, acronymsURI,
            afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 1)
        })
        
        try app.test(
            .DELETE, "\(acronymsURI)\(acronym.id!)",
            loggedInRequest: true,
            afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        try app.test(
            .GET, acronymsURI,
            afterResponse: { response in
            let newAcronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(newAcronyms.count, 0)
        })
    }
    
    func testSearchAcronymShort() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)search?term=OMG", afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 1)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        })
    }
    
    func testSearchAcronymLong() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)search?term=Oh+My+God", afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 1)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
        })
    }
    
    func testGetFirstAcronym() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        _ = try Acronym.create(on: app.db)
        _ = try Acronym.create(on: app.db)
        
        try app.test(.GET, "\(acronymsURI)first", afterResponse: { response in
            let firstAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(firstAcronym.id, acronym.id)
            XCTAssertEqual(firstAcronym.short, acronymShort)
            XCTAssertEqual(firstAcronym.long, acronymLong)
        })
    }
    
    func testSortingAcronyms() throws {
        let short2 = "LOL"
        let long2 = "Laugh Out Loud"
        let acronym0 = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronym1 = try Acronym.create(short: short2, long: long2, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)sorted", afterResponse: { response in
            let sortedAcronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(sortedAcronyms[0].id, acronym1.id)
            XCTAssertEqual(sortedAcronyms[1].id, acronym0.id)
        })
    }
    
    func testFirstSortedAcronyms() throws {
        let short2 = "LOL"
        let long2 = "Laugh Out Loud"
        _ = try Acronym.create(short: acronymShort, long: acronymLong, on: app.db)
        let acronym1 = try Acronym.create(short: short2, long: long2, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)sorted/first", afterResponse: { response in
            let firstAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(firstAcronym.id, acronym1.id)
        })
    }
    
    
    func testGettingAnAcronymsUser() throws {
        let user = try User.create(on: app.db)
        let acronym = try Acronym.create(user: user, on: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/user", afterResponse: { response in
            let acronymsUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(acronymsUser.id, user.id)
            XCTAssertEqual(acronymsUser.name, user.name)
            XCTAssertEqual(acronymsUser.username, user.username)
        })
    }
    
    func testAcronymsCategories() throws {
        let category0 = try App.Category.create(on: app.db)
        let category1 = try App.Category.create(name: "Funny", on: app.db)
        let acronym = try Acronym.create(on: app.db)
        
        try app.test(
            .POST, "\(acronymsURI)\(acronym.id!)/categories/\(category0.id!)",
            loggedInRequest: true)
        try app.test(
            .POST, "\(acronymsURI)\(acronym.id!)/categories/\(category1.id!)",
            loggedInRequest: true)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories", afterResponse: { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 2)
            if categories.count == 2 {
                XCTAssertEqual(categories[0].id, category0.id)
                XCTAssertEqual(categories[0].name, category0.name)
                XCTAssertEqual(categories[1].id, category1.id)
                XCTAssertEqual(categories[1].name, category1.name)
            }
        })
        
        try app.test(
            .DELETE, "\(acronymsURI)\(acronym.id!)/categories/\(category0.id!)",
            loggedInRequest: true,
            afterResponse: {
            response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories", afterResponse: { response in
            let newCategories = try response.content.decode([App.Category].self)
            XCTAssertEqual(newCategories.count, 1)
        })
    }
}
