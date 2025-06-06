//
//  ReadFilteredTagsDbRequest.swift
//  Zotero
//
//  Created by Michal Rentka on 18.04.2023.
//  Copyright © 2023 Corporation for Digital Scholarship. All rights reserved.
//

import Foundation

import RealmSwift

struct ReadFilteredTagsDbRequest: DbResponseRequest {
    typealias Response = Set<Tag>

    let collectionId: CollectionIdentifier
    let libraryId: LibraryIdentifier
    let showAutomatic: Bool
    let filters: [ItemsFilter]

    var needsWrite: Bool { return false }

    func process(in database: Realm) throws -> Set<Tag> {
        var predicates: [NSPredicate] = [.typedTagLibrary(with: self.libraryId)]

        switch collectionId {
        case .collection(let key):
            let keys: Set<String>
            if Defaults.shared.showSubcollectionItems {
                keys = database.selfAndSubcollectionKeys(for: key, libraryId: libraryId)
            } else {
                keys = Set([key])
            }
            var collectionPredicates: [NSPredicate] = []
            for key in keys {
                collectionPredicates.append(NSPredicate(format: "any item.collections.key = %@", key))
            }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: collectionPredicates))

        case .custom(let customType):
            switch customType {
            case .all, .publications:
                break

            case .unfiled:
                predicates.append(NSPredicate(format: "any item.collections.@count == 0"))

            case .trash:
                predicates.append(NSPredicate(format: "item.trash = true"))
            }

        case .search:
            break
        }

        if !showAutomatic {
            // Don't apply this filter to colored or emoji tags
            predicates.append(NSPredicate(format: "tag.color != \"\" or tag.emojiGroup != nil or type = %d", RTypedTag.Kind.manual.rawValue))
        }

        for filter in filters {
            switch filter {
            case .downloadedFiles:
                predicates.append(NSPredicate(format: "item.fileDownloaded = true or any item.children.fileDownloaded = true"))

            case .tags(let selectedNames):
                for name in selectedNames {
                    predicates.append(NSPredicate(format: "any item.tags.tag.name == %@", name))
                }
            }
        }

        let rTypedTags = database.objects(RTypedTag.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates))

        var tags: Set<Tag> = []
        for rTypedTag in rTypedTags {
            guard let tag = rTypedTag.tag.flatMap(Tag.init) else { continue }
            tags.insert(tag)
        }
        return tags
    }
}
