import Fluent

struct CreateEntry: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("entries")
            .id()
            .field("url", .string, .required)
            .unique(on: "url")
            .field("title", .string, .required)
            .field("published_at", .date, .required)
            .field("content", .string)
            .field("feed_id", .uuid, .required, .references("feeds", "id"))
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("entries").delete()
    }
}
