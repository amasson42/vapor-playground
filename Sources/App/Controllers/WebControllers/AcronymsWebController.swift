import Vapor
import Fluent
import Leaf

struct AcronymsWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let group = routes.grouped("acronyms")
        let protected = group.grouped(User.redirectMiddleware(path: "/login"))
        
        group.get(use: indexHandler)
        group.get(":acronymID", use: acronymHandler)
        protected.get("create", use: createAcronymHandler)
        protected.post("create", use: createAcronymPostHandler)
        protected.get(":acronymID", "edit", use: editAcronymHandler)
        protected.post(":acronymID", "edit", use: editAcronymPostHandler)
        protected.post(":acronymID", "delete", use: deleteAcronymHandler)
        
    }
    
    // path: /acronyms
    struct IndexContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        var acronyms: [Acronym]?
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        
        var context = IndexContext(
            title: "Acronyms",
            userLoggedIn: req.auth.has(User.self))
        
        return Acronym.query(on: req.db)
            .sort(\.$short)
            .all()
            .flatMap { acronyms in
                context.acronyms = acronyms.isEmpty ? nil : acronyms
                
                return req.view.render("Acronyms/index", context)
            }
    }
    
    // path: /acronyms/:acronymID
    struct AcronymContext: BaseContext {
        let title: String
        let userLoggedIn: Bool
        let acronym: Acronym
        let user: User
        let categories: [Category]
    }
    
    func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
                    .and(acronym.$categories.get(on: req.db))
                    .flatMap { user, categories in
                        let context = AcronymContext(
                            title: acronym.short,
                            userLoggedIn: req.auth.has(User.self),
                            acronym: acronym,
                            user: user,
                            categories: categories)
                        return req.view.render("Acronyms/acronym", context)
                    }
            }
    }
    
    struct CreateAcronymContext: BaseContext {
        let title = "Create An Acronym"
        let userLoggedIn: Bool
        let useSelect2 = true
        let editing = false
        let csrfToken: String
    }
    
    func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        let token = [UInt8].random(count: 16).base64
        
        let context = CreateAcronymContext(
            userLoggedIn: req.auth.has(User.self),
            csrfToken: token
        )
        req.session.data["CSRF_TOKEN"] = token
        return req.view.render("Acronyms/createAcronym", context)
    }
    
    struct CreateAcronymFormData: Content {
        let short: String
        let long: String
        let categories: [String]?
        let csrfToken: String?
    }
    
    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let data = try req.content.decode(CreateAcronymFormData.self)
        
        let user = try req.auth.require(User.self)
        
        let expectedToken = req.session.data["CSRF_TOKEN"]
        req.session.data["CSRF_TOKEN"] = nil
        guard let csrfToken = data.csrfToken,
              expectedToken == csrfToken else {
            throw Abort(.badRequest)
        }
        
        let acronym = try Acronym(
            short: data.short,
            long: data.long,
            userID: user.requireID())
        
        return acronym.save(on: req.db)
            .flatMap {
                guard let id = acronym.id else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }
                
                var categorySaves: [EventLoopFuture<Void>] = []
                
                for category in data.categories ?? [] {
                    categorySaves.append(
                        Category.addCategory(category, to: acronym, on: req)
                    )
                }
                
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves
                    .flatten(on: req.eventLoop)
                    .transform(to: redirect)
            }
    }
    
    struct EditAcronymContext: BaseContext {
        let title = "Edit Acronym"
        let userLoggedIn: Bool
        let useSelect2 = true
        let acronym: Acronym
        let editing = true
        let categories: [Category]
    }
    
    func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                
                acronym.$categories.get(on: req.db)
                    .flatMap { categories in
                    
                    let context = EditAcronymContext(
                        userLoggedIn: req.auth.has(User.self),
                        acronym: acronym,
                        categories: categories)
                    
                    return req.view.render("Acronyms/createAcronym", context)
                }
                
            }
        
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        let updateData = try req.content.decode(CreateAcronymFormData.self)
        
        return Acronym
            .find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { acronym in
                acronym.short = updateData.short
                acronym.long = updateData.long
                acronym.$user.id = userID
                
                guard let id = acronym.id else {
                    return req.eventLoop
                        .future(error: Abort(.internalServerError))
                }
                
                return acronym.save(on: req.db)
                    .flatMap {
                        acronym.$categories.get(on: req.db)
                    }
                    .flatMap { existingCategories in
                        let existingSet = Set<String>(existingCategories.map { $0.name })
                        
                        let newSet = Set<String>(updateData.categories ?? [])
                        
                        let categoriesToAdd = newSet.subtracting(existingSet)
                        let categoriesToRemove = existingSet.subtracting(newSet)
                        
                        var categoryResults: [EventLoopFuture<Void>] = []
                        
                        for newCategory in categoriesToAdd {
                            categoryResults.append(
                                Category.addCategory(newCategory, to: acronym, on: req)
                            )
                        }
                        
                        for categoryNameToRemove in categoriesToRemove {
                            let categoryToRemove = existingCategories.first {
                                $0.name == categoryNameToRemove
                            }
                            
                            if let category = categoryToRemove {
                                categoryResults.append(
                                    acronym.$categories.detach(category, on: req.db)
                                )
                            }
                        }
                        
                        let redirect = req.redirect(to: "/acronyms/\(id)")
                        
                        return categoryResults.flatten(on: req.eventLoop)
                            .transform(to: redirect)
                        
                    }
            }
    }
    
    func deleteAcronymHandler(_ req: Request) -> EventLoopFuture<Response> {
        return Acronym
            .find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.delete(on: req.db)
                    .transform(to: req.redirect(to: "/acronyms"))
            }
    }
    
}
