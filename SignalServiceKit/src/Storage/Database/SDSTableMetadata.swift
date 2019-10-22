//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDB
import SignalCoreKit

// TODO: We need to revise this.
@objc
public enum SDSColumnType: Int32 {
    case unicodeString
    case blob
    case bool
    case int
    case int64
    case double
    case primaryKey
}

@objc
public class SDSColumnMetadata: NSObject {

    @objc
    public let columnName: String

    @objc
    public let columnType: SDSColumnType

    @objc
    public let isOptional: Bool

    @objc
    public let isUnique: Bool

    // If true, this column isn't needed for deserialization and can be skipped in SELECT statements.
    @objc
    public let skipSelect: Bool

    @objc
    public let columnIndex: Int32

    @objc
    public init(columnName: String, columnType: SDSColumnType, isOptional: Bool = false, isUnique: Bool = false, skipSelect: Bool = false, columnIndex: Int32 = 0) {
        self.columnName = columnName
        self.columnType = columnType
        self.isOptional = isOptional
        self.isUnique = isUnique
        self.skipSelect = skipSelect
        self.columnIndex = columnIndex
    }
}

// MARK: -

// TODO: Consider adding uniqueIdColumn field.
@objc
public class SDSTableMetadata: NSObject {

    @objc
    public let collection: String

    @objc
    public let tableName: String

    @objc
    public let columns: [SDSColumnMetadata]

    public let databaseSelectionColumns: [Column]

    public let selectColumnNames: [String]

    @objc
    public init(collection: String, tableName: String, columns: [SDSColumnMetadata]) {
        self.collection = collection
        self.tableName = tableName
        self.columns = columns

        databaseSelectionColumns = columns.filter { (columMetaData) in
            return !columMetaData.skipSelect
            }.map { (columMetaData) in
                Column(columMetaData.columnName)
        }

        selectColumnNames = columns.filter { !$0.skipSelect }.map { $0.columnName }
    }

    public var columnNames: [String] {
        return columns.map { $0.columnName }
    }

    // MARK: - Table Creation

    public var hasValidTableName: Bool {
        // Only allow a-z, 0-9, and underscore
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_]+$", options: [])
        return regex.hasMatch(input: tableName)
    }

    public func createTable(database: Database) throws {
        if !hasValidTableName {
            owsFail("Invalid table name: \(tableName)")
        }

        try database.create(table: tableName) { (table) in
            for columnMetadata in self.columns {
                let column: ColumnDefinition
                switch columnMetadata.columnType {
                case .primaryKey:
                    column = table.autoIncrementedPrimaryKey(columnMetadata.columnName)
                case .unicodeString:
                    column = table.column(columnMetadata.columnName, .text)
                case .blob:
                    column = table.column(columnMetadata.columnName, .blob)
                case .bool:
                    column = table.column(columnMetadata.columnName, .boolean)
                case .int:
                    column = table.column(columnMetadata.columnName, .integer)
                case .int64:
                    column = table.column(columnMetadata.columnName, .integer)
                case .double:
                    column = table.column(columnMetadata.columnName, .double)
                }

                if !columnMetadata.isOptional {
                    column.notNull()
                }
                if columnMetadata.isUnique {
                    column.unique(onConflict: .fail)
                }
            }
        }
    }
}
