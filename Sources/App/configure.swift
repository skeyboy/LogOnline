import FluentSQLite
import Vapor
import MySQL
import FluentMySQL
import Authentication
typealias MySQLDatabaseCache = DatabaseKeyedCache<ConfiguredDatabase<MySQLDatabase>>

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(SessionsMiddleware.self)
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // 注册Authorware
     try services.register(AuthenticationProvider())

    // Configure a SQLite database
 
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.enableLogging(on: DatabaseIdentifier<MySQLDatabase>.mysql)
    
    _ =  config_db(database: &databases)//MySQL
    
    services.register(databases )
    
    services.register(KeyedCache.self) { container -> MySQLDatabaseCache  in
        let pool = try container.connectionPool(to: .mysql)
        return MySQLDatabaseCache.init(pool: pool )
    }
    config.prefer(MySQLDatabaseCache.self, for: KeyedCache.self)

    
    /// Configure migrations
    var migrations = MigrationConfig()
    config_migrations(migrations: &migrations)
    services.register(migrations)

}

func config_db(database: inout DatabasesConfig) -> MySQLDatabase{
    
    #if os(macOS)
    let  hostname =   "127.0.0.1"
    let password = "12345678"
    
    #else
    let   hostname =  "192.168.3.61"
    let password = "123456"
    #endif
    
    let mysqlConfig : MySQLDatabaseConfig =   MySQLDatabaseConfig.init(
        hostname:   hostname,
        
        port:   3306,
        username:   "root",
        password:   password,
        database:   "LogOnline",
        capabilities:   .default,
        characterSet:   .utf8mb4_unicode_ci,
        transport:   .cleartext
    )
    let mysqlDb: MySQLDatabase = MySQLDatabase.init(config: mysqlConfig)
    database.add(database: mysqlDb, as: DatabaseIdentifier<MySQLDatabase>.mysql)
    return mysqlDb
}
func config_migrations(migrations:inout  MigrationConfig){
    
   
    migrations.add(model: LOUser.self, database: .mysql)
    
    migrations.add(model: LODevice.self, database: .mysql)
    migrations.add(model: LOGroup.self, database: .mysql)
    migrations.add(model: LOGroupUserPivot.self, database: .mysql)
    migrations.add(model: LOLog.self, database: .mysql)
    migrations.add(model: LOUserDevicePivot.self, database: .mysql)
    migrations.add(model: CacheEntry<MySQLDatabase>.self, database: .mysql)
}

