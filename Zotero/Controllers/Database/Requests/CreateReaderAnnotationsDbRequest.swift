//
//  CreateReaderAnnotationsDbRequest.swift
//  Zotero
//
//  Created by Miltiadis Vasilakis on 20/9/24.
//  Copyright © 2024 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import CocoaLumberjackSwift
import RealmSwift

protocol CreateReaderAnnotationsDbRequest: DbRequest {
    associatedtype Annotation: ReaderAnnotation

    var attachmentKey: String { get }
    var libraryId: LibraryIdentifier { get }
    var annotations: [Annotation] { get }
    var userId: Int { get }
    var schemaController: SchemaController { get }

    func create(annotation: Annotation, parent: RItem, in database: Realm)
    func addFields(for annotation: Annotation, to item: RItem, database: Realm)
    func addExtraFields(for annotation: Annotation, to item: RItem, database: Realm)
    func addTags(for annotation: Annotation, to item: RItem, database: Realm)
    func addAdditionalProperties(for annotation: Annotation, fromRestore: Bool, to item: RItem, changes: inout RItemChanges, database: Realm)
}

extension CreateReaderAnnotationsDbRequest {
    var needsWrite: Bool { return true }

    func process(in database: Realm) throws {
        guard let parent = database.objects(RItem.self).uniqueObject(key: attachmentKey, libraryId: libraryId) else { return }

        for annotation in annotations {
            create(annotation: annotation, parent: parent, in: database)
        }
    }

    func create(annotation: Annotation, parent: RItem, in database: Realm) {
        let fromRestore: Bool
        let item: RItem

        if let _item = database.objects(RItem.self).uniqueObject(key: annotation.key, libraryId: libraryId) {
            if !_item.deleted {
                // If item exists and is not deleted locally, we can ignore this request
                return
            }

            // If item exists and was already deleted locally and not yet synced, we re-add the item
            item = _item
            item.deleted = false
            fromRestore = true
        } else {
            // If item didn't exist, create it
            item = RItem()
            item.key = annotation.key
            item.rawType = ItemTypes.annotation
            item.localizedType = schemaController.localized(itemType: ItemTypes.annotation) ?? ""
            item.libraryId = libraryId
            item.dateAdded = annotation.dateAdded
            database.add(item)
            fromRestore = false
        }

        item.annotationType = annotation.type.rawValue
        item.syncState = .synced
        item.changeType = .user
        item.htmlFreeContent = annotation.comment.isEmpty ? nil : annotation.comment.strippedRichTextTags
        item.dateModified = annotation.dateModified
        item.parent = parent

        if annotation.isAuthor(currentUserId: userId) {
            let user = database.object(ofType: RUser.self, forPrimaryKey: userId)
            item.createdBy = user
            if user == nil {
                DDLogWarn("CreateReaderAnnotationsDbRequest: user not found for userId \(userId)")
            }
        }

        addFields(for: annotation, to: item, database: database)
        addExtraFields(for: annotation, to: item, database: database)
        addTags(for: annotation, to: item, database: database)
        // We need to submit tags on creation even if they are empty, so we need to mark them as changed
        var changes: RItemChanges = [.parent, .fields, .type, .tags]
        addAdditionalProperties(for: annotation, fromRestore: fromRestore, to: item, changes: &changes, database: database)
        item.changes.append(RObjectChange.create(changes: changes))
    }

    func addFields(for annotation: Annotation, to item: RItem, database: Realm) {
        for field in FieldKeys.Item.Annotation.mandatoryApiFields(for: annotation.type) {
            let rField = RItemField()
            rField.key = field.key
            rField.baseKey = field.baseKey
            rField.changed = true

            switch field.key {
            case FieldKeys.Item.Annotation.type:
                rField.value = annotation.type.rawValue

            case FieldKeys.Item.Annotation.color:
                rField.value = annotation.color

            case FieldKeys.Item.Annotation.comment:
                rField.value = annotation.comment

            case FieldKeys.Item.Annotation.sortIndex:
                rField.value = annotation.sortIndex
                item.annotationSortIndex = annotation.sortIndex

            case FieldKeys.Item.Annotation.text:
                rField.value = annotation.text ?? ""

            default:
                break
            }

            item.fields.append(rField)
        }
    }
}
