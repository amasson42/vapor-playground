@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    
    var app: Application!
    let categoriesURI = "/api/categories/"
    let categoryName = "Teenager"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app?.shutdown()
    }
    
    func testCategoriesCanBeRetrievedFromAPI() throws {
        let category = try Category.create(name: categoryName, on: app.db)
        _ = try Category.create(on: app.db)
        
        try app.test(.GET, categoriesURI, afterResponse: { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 2)
            XCTAssertEqual(categories[0].name, categoryName)
            XCTAssertEqual(categories[0].id, category.id)
        })
    }
    
    func testCategoryCanBeSavedWithAPI() throws {
        let category = Category(name: categoryName)
        
        try app.test(.POST, categoriesURI, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            let receivedCategory = try response.content.decode(Category.self)
            XCTAssertEqual(receivedCategory.name, categoryName)
            XCTAssertNotNil(receivedCategory.id)
            
            try app.test(.GET, categoriesURI, afterResponse: { response in
                let categories = try response.content.decode([App.Category].self)
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, categoryName)
                XCTAssertEqual(categories[0].id, receivedCategory.id)
            })
        })
    }
    
    func testGettingASingleCategoryFromTheAPI() throws {
        let category = try Category.create(name: categoryName, on: app.db)
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)", afterResponse: { response in
            let returnedCategory = try response.content.decode(Category.self)
            XCTAssertEqual(returnedCategory.name, categoryName)
            XCTAssertEqual(returnedCategory.id, category.id)
        })
    }
    
    func testGettingACategoriesAcronymsFromTheAPI() throws {
        let acronym0 = try Acronym.create(short: "OMG",
                                          long: "Oh My God",
                                          on: app.db)
        let acronym1 = try Acronym.create(on: app.db)
        
        let category = try Category.create(name: categoryName, on: app.db)
        
        try app.test(.POST, "/api/acronyms/\(acronym0.id!)/categories/\(category.id!)")
        try app.test(.POST, "/api/acronyms/\(acronym1.id!)/categories/\(category.id!)")
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/acronyms", afterResponse: { response in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(acronyms.count, 2)
            
            XCTAssertEqual(acronyms[0].id, acronym0.id)
            XCTAssertEqual(acronyms[0].short, acronym0.short)
            XCTAssertEqual(acronyms[0].long, acronym0.long)
            
            XCTAssertEqual(acronyms[1].id, acronym1.id)
            XCTAssertEqual(acronyms[1].short, acronym1.short)
            XCTAssertEqual(acronyms[1].long, acronym1.long)
        })
    }
}
