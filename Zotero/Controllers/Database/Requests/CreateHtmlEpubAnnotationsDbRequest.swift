//
//  CreateHtmlEpubAnnotationsDbRequest.swift
//  Zotero
//
//  Created by Michal Rentka on 28.09.2023.
//  Copyright © 2023 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RealmSwift

struct CreateHtmlEpubAnnotationsDbRequest: CreateReaderAnnotationsDbRequest {
    let attachmentKey: String
    let libraryId: LibraryIdentifier
    let annotations: [HtmlEpubAnnotation]
    let userId: Int

    unowned let schemaController: SchemaController

    func addExtraFields(for annotation: HtmlEpubAnnotation, to item: RItem, database: Realm) {
        for field in FieldKeys.Item.Annotation.extraHtmlEpubFields(for: annotation.type) {
            let value: String

            switch field.key {
            case FieldKeys.Item.Annotation.pageLabel:
                value = annotation.pageLabel

            case FieldKeys.Item.Annotation.Position.htmlEpubType where field.baseKey == FieldKeys.Item.Annotation.position:
                guard let htmlEpubType = annotation.position[FieldKeys.Item.Annotation.Position.htmlEpubType] as? String else { continue }
                value = htmlEpubType

            case FieldKeys.Item.Annotation.Position.htmlEpubValue where field.baseKey == FieldKeys.Item.Annotation.position:
                guard let htmlEpubValue = annotation.position[FieldKeys.Item.Annotation.Position.htmlEpubValue] as? String else { continue }
                value = htmlEpubValue

            default:
                continue
            }

            let rField = RItemField()
            rField.key = field.key
            rField.baseKey = field.baseKey
            rField.changed = true
            rField.value = value
            item.fields.append(rField)
        }
    }

    func addTags(for annotation: HtmlEpubAnnotation, to item: RItem, database: Realm) {
        let allTags = database.objects(RTag.self)

        for tag in annotation.tags {
            guard let rTag = allTags.filter(.name(tag.name)).first else { continue }

            let rTypedTag = RTypedTag()
            rTypedTag.type = .manual
            database.add(rTypedTag)

            rTypedTag.item = item
            rTypedTag.tag = rTag
        }
    }

    func addAdditionalProperties(for annotation: HtmlEpubAnnotation, fromRestore: Bool, to item: RItem, changes: inout RItemChanges, database: Realm) { }
}
