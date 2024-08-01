import Fluent

struct CreateFeed: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("feeds")
            .id()
            .field("url", .string, .required)
            .unique(on: "url")
            .field("title", .string, .required)
            .field("page_url", .string)
            .field("overview", .string)
            .field("image_url", .string)
            .field("created_at", .date)
            .field("updated_at", .date)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("feeds").delete()
    }
}
