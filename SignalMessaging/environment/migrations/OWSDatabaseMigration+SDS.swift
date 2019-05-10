//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Record

public struct DatabaseMigrationRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    public static let databaseTableName: String = OWSDatabaseMigrationSerializer.table.tableName

    public let id: UInt64

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    public let recordType: SDSRecordType
    public let uniqueId: String

    public enum CodingKeys: String, CodingKey, ColumnExpression, CaseIterable {
        case id
        case recordType
        case uniqueId
    }

    public static func columnName(_ column: DatabaseMigrationRecord.CodingKeys) -> String {
        return column.rawValue
    }

}

// MARK: - StringInterpolation

public extension String.StringInterpolation {
    mutating func appendInterpolation(columnForDatabaseMigration column: DatabaseMigrationRecord.CodingKeys) {
        appendLiteral(DatabaseMigrationRecord.columnName(column))
    }
}

// MARK: - Deserialization

// TODO: Remove the other Deserialization extension.
// TODO: SDSDeserializer.
// TODO: Rework metadata to not include, for example, columns, column indices.
extension OWSDatabaseMigration {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func fromRecord(_ record: DatabaseMigrationRecord) throws -> OWSDatabaseMigration {

        switch record.recordType {
        case ._100RemoveTSRecipientsMigration:

            let uniqueId: String = record.uniqueId

            return OWS100RemoveTSRecipientsMigration(uniqueId: uniqueId)

        case ._101ExistingUsersBlockOnIdentityChange:

            let uniqueId: String = record.uniqueId

            return OWS101ExistingUsersBlockOnIdentityChange(uniqueId: uniqueId)

        case ._102MoveLoggingPreferenceToUserDefaults:

            let uniqueId: String = record.uniqueId

            return OWS102MoveLoggingPreferenceToUserDefaults(uniqueId: uniqueId)

        case ._103EnableVideoCalling:

            let uniqueId: String = record.uniqueId

            return OWS103EnableVideoCalling(uniqueId: uniqueId)

        case ._104CreateRecipientIdentities:

            let uniqueId: String = record.uniqueId

            return OWS104CreateRecipientIdentities(uniqueId: uniqueId)

        case ._105AttachmentFilePaths:

            let uniqueId: String = record.uniqueId

            return OWS105AttachmentFilePaths(uniqueId: uniqueId)

        case ._107LegacySounds:

            let uniqueId: String = record.uniqueId

            return OWS107LegacySounds(uniqueId: uniqueId)

        case ._108CallLoggingPreference:

            let uniqueId: String = record.uniqueId

            return OWS108CallLoggingPreference(uniqueId: uniqueId)

        case ._109OutgoingMessageState:

            let uniqueId: String = record.uniqueId

            return OWS109OutgoingMessageState(uniqueId: uniqueId)

        case .databaseMigration:

            let uniqueId: String = record.uniqueId

            return OWSDatabaseMigration(uniqueId: uniqueId)

        case .resaveCollectionDBMigration:

            let uniqueId: String = record.uniqueId

            return OWSResaveCollectionDBMigration(uniqueId: uniqueId)

        default:
            owsFailDebug("Unexpected record type: \(record.recordType)")
            throw SDSError.invalidValue
        }
    }
}

// MARK: - SDSSerializable

extension OWSDatabaseMigration: SDSSerializable {
    public var serializer: SDSSerializer {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        switch self {
        case let model as OWS109OutgoingMessageState:
            assert(type(of: model) == OWS109OutgoingMessageState.self)
            return OWS109OutgoingMessageStateSerializer(model: model)
        case let model as OWSResaveCollectionDBMigration:
            assert(type(of: model) == OWSResaveCollectionDBMigration.self)
            return OWSResaveCollectionDBMigrationSerializer(model: model)
        case let model as OWS108CallLoggingPreference:
            assert(type(of: model) == OWS108CallLoggingPreference.self)
            return OWS108CallLoggingPreferenceSerializer(model: model)
        case let model as OWS107LegacySounds:
            assert(type(of: model) == OWS107LegacySounds.self)
            return OWS107LegacySoundsSerializer(model: model)
        case let model as OWS105AttachmentFilePaths:
            assert(type(of: model) == OWS105AttachmentFilePaths.self)
            return OWS105AttachmentFilePathsSerializer(model: model)
        case let model as OWS104CreateRecipientIdentities:
            assert(type(of: model) == OWS104CreateRecipientIdentities.self)
            return OWS104CreateRecipientIdentitiesSerializer(model: model)
        case let model as OWS103EnableVideoCalling:
            assert(type(of: model) == OWS103EnableVideoCalling.self)
            return OWS103EnableVideoCallingSerializer(model: model)
        case let model as OWS102MoveLoggingPreferenceToUserDefaults:
            assert(type(of: model) == OWS102MoveLoggingPreferenceToUserDefaults.self)
            return OWS102MoveLoggingPreferenceToUserDefaultsSerializer(model: model)
        case let model as OWS101ExistingUsersBlockOnIdentityChange:
            assert(type(of: model) == OWS101ExistingUsersBlockOnIdentityChange.self)
            return OWS101ExistingUsersBlockOnIdentityChangeSerializer(model: model)
        case let model as OWS100RemoveTSRecipientsMigration:
            assert(type(of: model) == OWS100RemoveTSRecipientsMigration.self)
            return OWS100RemoveTSRecipientsMigrationSerializer(model: model)
        default:
            return OWSDatabaseMigrationSerializer(model: self)
        }
    }
}

// MARK: - Table Metadata

extension OWSDatabaseMigrationSerializer {

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    static let recordTypeColumn = SDSColumnMetadata(columnName: "recordType", columnType: .int, columnIndex: 0)
    static let idColumn = SDSColumnMetadata(columnName: "id", columnType: .primaryKey, columnIndex: 1)
    static let uniqueIdColumn = SDSColumnMetadata(columnName: "uniqueId", columnType: .unicodeString, columnIndex: 2)

    // TODO: We should decide on a naming convention for
    //       tables that store models.
    public static let table = SDSTableMetadata(tableName: "model_OWSDatabaseMigration", columns: [
        recordTypeColumn,
        idColumn,
        uniqueIdColumn
        ])

}

// MARK: - Deserialization

extension OWSDatabaseMigrationSerializer {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func sdsDeserialize(statement: SelectStatement) throws -> OWSDatabaseMigration {

        if OWSIsDebugBuild() {
            guard statement.columnNames == table.selectColumnNames else {
                owsFailDebug("Unexpected columns: \(statement.columnNames) != \(table.selectColumnNames)")
                throw SDSError.invalidResult
            }
        }

        // SDSDeserializer is used to convert column values into Swift values.
        let deserializer = SDSDeserializer(sqliteStatement: statement.sqliteStatement)
        let recordTypeValue = try deserializer.int(at: 0)
        guard let recordType = SDSRecordType(rawValue: UInt(recordTypeValue)) else {
            owsFailDebug("Invalid recordType: \(recordTypeValue)")
            throw SDSError.invalidResult
        }
        switch recordType {
        case ._100RemoveTSRecipientsMigration:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS100RemoveTSRecipientsMigration(uniqueId: uniqueId)

        case ._101ExistingUsersBlockOnIdentityChange:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS101ExistingUsersBlockOnIdentityChange(uniqueId: uniqueId)

        case ._102MoveLoggingPreferenceToUserDefaults:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS102MoveLoggingPreferenceToUserDefaults(uniqueId: uniqueId)

        case ._103EnableVideoCalling:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS103EnableVideoCalling(uniqueId: uniqueId)

        case ._104CreateRecipientIdentities:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS104CreateRecipientIdentities(uniqueId: uniqueId)

        case ._105AttachmentFilePaths:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS105AttachmentFilePaths(uniqueId: uniqueId)

        case ._107LegacySounds:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS107LegacySounds(uniqueId: uniqueId)

        case ._108CallLoggingPreference:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS108CallLoggingPreference(uniqueId: uniqueId)

        case ._109OutgoingMessageState:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWS109OutgoingMessageState(uniqueId: uniqueId)

        case .databaseMigration:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWSDatabaseMigration(uniqueId: uniqueId)

        case .resaveCollectionDBMigration:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)

            return OWSResaveCollectionDBMigration(uniqueId: uniqueId)

        default:
            owsFail("Invalid record type \(recordType)")
        }
    }
}

// MARK: - Save/Remove/Update

@objc
extension OWSDatabaseMigration {
    public func anySave(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            save(with: ydbTransaction)
        case .grdbWrite(let grdbTransaction):
            SDSSerialization.save(entity: self, transaction: grdbTransaction)
        }
    }

    // This method is used by "updateWith..." methods.
    //
    // This model may be updated from many threads. We don't want to save
    // our local copy (this instance) since it may be out of date.  We also
    // want to avoid re-saving a model that has been deleted.  Therefore, we
    // use "updateWith..." methods to:
    //
    // a) Update a property of this instance.
    // b) If a copy of this model exists in the database, load an up-to-date copy,
    //    and update and save that copy.
    // b) If a copy of this model _DOES NOT_ exist in the database, do _NOT_ save
    //    this local instance.
    //
    // After "updateWith...":
    //
    // a) Any copy of this model in the database will have been updated.
    // b) The local property on this instance will always have been updated.
    // c) Other properties on this instance may be out of date.
    //
    // All mutable properties of this class have been made read-only to
    // prevent accidentally modifying them directly.
    //
    // This isn't a perfect arrangement, but in practice this will prevent
    // data loss and will resolve all known issues.
    public func anyUpdateWith(transaction: SDSAnyWriteTransaction, block: (OWSDatabaseMigration) -> Void) {
        guard let uniqueId = uniqueId else {
            owsFailDebug("Missing uniqueId.")
            return
        }

        guard let dbCopy = type(of: self).anyFetch(uniqueId: uniqueId,
                                                   transaction: transaction) else {
            return
        }

        block(self)
        block(dbCopy)

        dbCopy.anySave(transaction: transaction)
    }

    public func anyRemove(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            remove(with: ydbTransaction)
        case .grdbWrite(let grdbTransaction):
            SDSSerialization.delete(entity: self, transaction: grdbTransaction)
        }
    }
}

// MARK: - OWSDatabaseMigrationCursor

@objc
public class OWSDatabaseMigrationCursor: NSObject {
    private let cursor: SDSCursor<OWSDatabaseMigration>

    init(cursor: SDSCursor<OWSDatabaseMigration>) {
        self.cursor = cursor
    }

    // TODO: Revisit error handling in this class.
    public func next() throws -> OWSDatabaseMigration? {
        return try cursor.next()
    }

    public func all() throws -> [OWSDatabaseMigration] {
        return try cursor.all()
    }
}

// MARK: - Obj-C Fetch

// TODO: We may eventually want to define some combination of:
//
// * fetchCursor, fetchOne, fetchAll, etc. (ala GRDB)
// * Optional "where clause" parameters for filtering.
// * Async flavors with completions.
//
// TODO: I've defined flavors that take a read transaction.
//       Or we might take a "connection" if we end up having that class.
@objc
extension OWSDatabaseMigration {
    public class func grdbFetchCursor(transaction: GRDBReadTransaction) -> OWSDatabaseMigrationCursor {
        return OWSDatabaseMigrationCursor(cursor: SDSSerialization.fetchCursor(tableMetadata: OWSDatabaseMigrationSerializer.table,
                                                                   transaction: transaction,
                                                                   deserialize: OWSDatabaseMigrationSerializer.sdsDeserialize))
    }

    // Fetches a single model by "unique id".
    public class func anyFetch(uniqueId: String,
                               transaction: SDSAnyReadTransaction) -> OWSDatabaseMigration? {
        assert(uniqueId.count > 0)

        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return OWSDatabaseMigration.fetch(uniqueId: uniqueId, transaction: ydbTransaction)
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT * FROM \(DatabaseMigrationRecord.databaseTableName) WHERE \(columnForDatabaseMigration: .uniqueId) = ?"
            return grdbFetchOne(sql: sql, arguments: [uniqueId], transaction: grdbTransaction)
        }
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    // Traversal aborts if the visitor returns false.
    public class func anyVisitAll(transaction: SDSAnyReadTransaction, visitor: @escaping (OWSDatabaseMigration) -> Bool) {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            OWSDatabaseMigration.enumerateCollectionObjects(with: ydbTransaction) { (object, stop) in
                guard let value = object as? OWSDatabaseMigration else {
                    owsFailDebug("unexpected object: \(type(of: object))")
                    return
                }
                guard visitor(value) else {
                    stop.pointee = true
                    return
                }
            }
        case .grdbRead(let grdbTransaction):
            do {
                let cursor = OWSDatabaseMigration.grdbFetchCursor(transaction: grdbTransaction)
                while let value = try cursor.next() {
                    guard visitor(value) else {
                        return
                    }
                }
            } catch let error as NSError {
                owsFailDebug("Couldn't fetch models: \(error)")
            }
        }
    }

    // Does not order the results.
    public class func anyFetchAll(transaction: SDSAnyReadTransaction) -> [OWSDatabaseMigration] {
        var result = [OWSDatabaseMigration]()
        anyVisitAll(transaction: transaction) { (model) in
            result.append(model)
            return true
        }
        return result
    }
}

// MARK: - Swift Fetch

extension OWSDatabaseMigration {
    public class func grdbFetchCursor(sql: String,
                                      arguments: [DatabaseValueConvertible]?,
                                      transaction: GRDBReadTransaction) -> OWSDatabaseMigrationCursor {
        var statementArguments: StatementArguments?
        if let arguments = arguments {
            guard let statementArgs = StatementArguments(arguments) else {
                owsFail("Could not convert arguments.")
            }
            statementArguments = statementArgs
        }
        return OWSDatabaseMigrationCursor(cursor: SDSSerialization.fetchCursor(sql: sql,
                                                             arguments: statementArguments,
                                                             transaction: transaction,
                                                                   deserialize: OWSDatabaseMigrationSerializer.sdsDeserialize))
    }

    public class func grdbFetchOne(sql: String,
                                   arguments: StatementArguments,
                                   transaction: GRDBReadTransaction) -> OWSDatabaseMigration? {
        assert(sql.count > 0)

        do {
            guard let record = try DatabaseMigrationRecord.fetchOne(transaction.database, sql: sql, arguments: arguments) else {
                return nil
            }

            return try OWSDatabaseMigration.fromRecord(record)
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class OWSDatabaseMigrationSerializer: SDSSerializer {

    private let model: OWSDatabaseMigration
    public required init(model: OWSDatabaseMigration) {
        self.model = model
    }

    public func serializableColumnTableMetadata() -> SDSTableMetadata {
        return OWSDatabaseMigrationSerializer.table
    }

    public func insertColumnNames() -> [String] {
        // When we insert a new row, we include the following columns:
        //
        // * "record type"
        // * "unique id"
        // * ...all columns that we set when updating.
        return [
            OWSDatabaseMigrationSerializer.recordTypeColumn.columnName,
            uniqueIdColumnName()
            ] + updateColumnNames()

    }

    public func insertColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [
            SDSRecordType.databaseMigration.rawValue
            ] + [uniqueIdColumnValue()] + updateColumnValues()
        if OWSIsDebugBuild() {
            if result.count != insertColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(insertColumnNames().count)")
            }
        }
        return result
    }

    public func updateColumnNames() -> [String] {
        return []
    }

    public func updateColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [

        ]
        if OWSIsDebugBuild() {
            if result.count != updateColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(updateColumnNames().count)")
            }
        }
        return result
    }

    public func uniqueIdColumnName() -> String {
        return OWSDatabaseMigrationSerializer.uniqueIdColumn.columnName
    }

    // TODO: uniqueId is currently an optional on our models.
    //       We should probably make the return type here String?
    public func uniqueIdColumnValue() -> DatabaseValueConvertible {
        // FIXME remove force unwrap
        return model.uniqueId!
    }
}
