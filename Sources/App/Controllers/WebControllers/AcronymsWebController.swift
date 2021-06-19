import Vapor
import Fluent
import Leaf

struct AcronymsWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("acronyms")
        
        group.get(use: indexHandler)
        group.get(":acronymID", use: acronymHandler)
        group.get("create", use: createAcronymHandler)
        group.post("create", use: createAcronymPostHandler)
        group.get(":acronymID", "edit", use: editAcronymHandler)
        group.post(":acronymID", "edit", use: editAcronymPostHandler)
        group.post(":acronymID", "delete", use: deleteAcronymHandler)
        
    }
    
    // path: /acronyms
    struct IndexContext: BaseContext {
        let title: String
        var acronyms: [Acronym]?
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        
        var context = IndexContext(title: "Acronyms")
        
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
                            acronym: acronym,
                            user: user,
                            categories: categories)
                        return req.view.render("Acronyms/acronym", context)
                    }
            }
    }
    
    struct CreateAcronymContext: BaseContext {
        let useSelect2 = true
        let title = "Create An Acronym"
        let users: [User]
        let editing = false
    }
    
    func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        return User.query(on: req.db).all().flatMap { users in
            let context = CreateAcronymContext(users: users)
            
            return req.view.render("Acronyms/createAcronym", context)
        }
        
    }
    
    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let data = try req.content.decode(CreateAcronymFormData.self)
        
        let acronym = Acronym(
            short: data.short,
            long: data.long,
            userID: data.userID)
        
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
        let useSelect2 = true
        let title = "Edit Acronym"
        let acronym: Acronym
        let users: [User]
        let editing = true
        let categories: [Category]
    }
    
    func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        
        let acronymFuture = Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        let userQuery = User.query(on: req.db).all()
        
        return acronymFuture.and(userQuery)
            .flatMap { acronym, users in
                
                acronym.$categories.get(on: req.db).flatMap {
                    categories in
                    
                    let context = EditAcronymContext(
                        acronym: acronym,
                        users: users,
                        categories: categories)
                    
                    return req.view.render("Acronyms/createAcronym", context)
                }
                
            }
        
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        
        let updateData = try req.content.decode(CreateAcronymFormData.self)
        
        return Acronym
            .find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { acronym in
                acronym.short = updateData.short
                acronym.long = updateData.long
                acronym.$user.id = updateData.userID
                
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

struct CreateAcronymFormData: Content {
    let userID: UUID
    let short: String
    let long: String
    let categories: [String]?
}
