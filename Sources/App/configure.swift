import Vapor
import Fluent
import FluentPostgresDriver
//import FluentSQLiteDriver
import FluentMySQLDriver
import FluentMongoDriver
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.logger.logLevel = .debug
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.logger.debug("Using Middleware directory: \(app.directory.publicDirectory)")
    
    // MARK: Use database
    
    if (app.environment == .testing) {
        app.databases.use(.postgres(
            hostname: "localhost",
            port: Environment.get("DATABASE_PORT")?.toInt ?? 5433,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor-test"
        ), as: .psql)
    } else {
        app.databases.use(.postgres(
            hostname: Environment.tilEnv.DATABASE_HOST,
            port: Environment.tilEnv.DATABASE_PORT,
            username: Environment.tilEnv.DATABASE_USERNAME,
            password: Environment.tilEnv.DATABASE_PASSWORD,
            database: Environment.tilEnv.DATABASE_NAME
        ), as: .psql)
    }
    
//    app.databases.use(.mysql(
//        hostname: Environment.tilEnv.DATABASE_HOST,
//        port: Environment.tilEnv.DATABASE_PORT,
//        username: Environment.tilEnv.DATABASE_USERNAME,
//        password: Environment.tilEnv.DATABASE_PASSWORD,
//        database: Environment.tilEnv.DATABASE_NAME,
//        tlsConfiguration: .forClient(certificateVerification: .none)
//    ), as: .mysql)
    
//    try app.databases.use(.mongo(connectionString: "mongodb://\(Environment.tilEnv.DATABASE_HOST):\(Environment.tilEnv.DATABASE_PORT)/\(Environment.tilEnv.DATABASE_NAME)"),
//                              as: .mongo)
    
//    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    
    // MARK: Migration scripts
    
    /// The order of this migrations call matter.
    /// It will create database tables and if there is relationships, then they have to exist in correct order
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAdminUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAcronym())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateAcronymCategoryPivot())
    
    try app.autoMigrate().wait()
    
    // MARK: View rendering
    
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}
