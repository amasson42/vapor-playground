import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import FluentMySQLDriver
import FluentMongoDriver
import Leaf
import SendGrid
import Redis

// configures your application
public func configure(_ app: Application) throws {
    
    app.middleware.use(LogMiddleware())
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.sessions.use(.redis)
    app.middleware.use(app.sessions.middleware)
    
    for dir in TILEnv.dynamicDirectories {
        try? FileManager.default.createDirectory(
            atPath: app.directory.publicDirectory + "dynamic/" + dir,
            withIntermediateDirectories: true)
    }
    
    // MARK: Use database
    
    if (app.environment == .testing) {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT")?.toInt ?? 5433,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor-test"
        ), as: .psql)
        app.redis.configuration = try RedisConfiguration(
            hostname: Environment.get("REDIS_HOST") ?? "localhost",
            port: Environment.get("REDIS_PORT")?.toInt ?? 6378)
    } else {
        app.databases.use(.postgres(
            hostname: Environment.tilEnv.DATABASE_HOST,
            port: Environment.tilEnv.DATABASE_PORT,
            username: Environment.tilEnv.DATABASE_USERNAME,
            password: Environment.tilEnv.DATABASE_PASSWORD,
            database: Environment.tilEnv.DATABASE_NAME
        ), as: .psql)
        app.redis.configuration = try RedisConfiguration(
            hostname: Environment.tilEnv.REDIS_HOST,
            port: Environment.tilEnv.REDIS_PORT)
    }
    app.databases.middleware.use(UserMiddleware(), on: .psql)
    app.caches.use(.redis)
    
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
    
    app.migrations.add(CacheEntry.migration)
    
    app.migrations.add(CreateUser_v100())
    app.migrations.add(CreateToken_v100())
    app.migrations.add(CreateResetPasswordToken_v100())
    app.migrations.add(CreateAcronym_v100())
    app.migrations.add(CreateCategory_v100())
    app.migrations.add(CreateAcronymCategoryPivot_v100())
    
    app.migrations.add(CreateUser_v110())
    app.migrations.add(CreateCategory_v110())
    app.migrations.add(CreatePokemon_v110())
    app.migrations.add(CreateTodo_v110())
    
    app.migrations.add(CreateUser_v120())
    app.migrations.add(CreateAcronym_v120())
    
    
    
    if app.environment == .development || app.environment == .testing {
        app.migrations.add(CreateAdminUser())
    }
    
    var connectedToDb = false
    while !connectedToDb {
        do {
            try app.autoMigrate().wait()
            connectedToDb = true
        } catch {
            if app.environment == .testing {
                throw error
            } else {
                app.logger.notice("Error connecting to database: \(error)... Trying again in 3 seconds")
                sleep(3)
            }
        }
    }
    
    // MARK: View rendering
    
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
    
    if Environment.tilEnv.SENDGRID_API_KEY != nil {
        app.sendgrid.initialize()
    }
}
