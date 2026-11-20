// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Context: Codable, Hashable {
  public let ancestors: [Status]
  public let descendants: [Status]

  public init(ancestors: [Status], descendants: [Status]) {
    self.ancestors = ancestors
    self.descendants = descendants
  }
}

extension Context {
  public var threadOrdered: Self {
    .init(ancestors: Self.threadOrdered(ancestors), descendants: Self.threadOrdered(descendants))
  }
}

extension Context {
  fileprivate static func chronological(_ lhs: Status, _ rhs: Status) -> Bool {
    lhs.createdAt != rhs.createdAt ? lhs.createdAt < rhs.createdAt : lhs.id < rhs.id
  }

  fileprivate static func threadOrdered(_ statuses: [Status]) -> [Status] {
    let ids = Set(statuses.map(\.id))
    var childrenByParentId = [Status.Id: [Status]]()
    var roots = [Status]()

    for status in statuses {
      if let parentId = status.inReplyToId, ids.contains(parentId), parentId != status.id {
        childrenByParentId[parentId, default: []].append(status)
      } else {
        roots.append(status)
      }
    }

    var result = [Status]()
    var visited = Set<Status.Id>()

    func visit(_ status: Status) {
      guard visited.insert(status.id).inserted else { return }

      result.append(status)
      childrenByParentId[status.id]?.sorted(by: chronological).forEach(visit)
    }

    roots.sorted(by: chronological).forEach(visit)
    statuses.filter { !visited.contains($0.id) }.sorted(by: chronological).forEach(visit)

    return result
  }
}
