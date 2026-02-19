// Copyright © 2026 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct FilterV2Info: Codable, Hashable, FetchableRecord {
  let filter: FilterV2Record
  let keywords: [FilterV2KeywordRecord]
  let statuses: [FilterV2StatusRecord]

  static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == FilterV2Record {
    request
      .including(optional: FilterV2Record.keywords)
      .including(optional: FilterV2Record.statuses)
  }

  static func request(_ request: QueryInterfaceRequest<FilterV2Record>) -> QueryInterfaceRequest<Self> {
    addingIncludes(request).asRequest(of: self)
  }
}

/// Persistence layer version of `Mastodon.FilterV2`.
struct FilterV2Record: ContentDatabaseRecord, Hashable {
  let id: FilterV2.ID
  let title: String
  let context: [Filter.Context]
  let expiresAt: Date?
  let filterAction: FilterV2.Action

  enum Columns: String, ColumnExpression {
    case id
    case title
    case context
    case expiresAt
    case action
  }

  static let keywords = hasMany(
    FilterV2KeywordRecord.self,
    using: ForeignKey([Columns.id], to: [FilterV2KeywordRecord.Columns.filterId])
  )
  var keywords: QueryInterfaceRequest<FilterV2KeywordRecord> {
    request(for: Self.keywords)
  }

  static let statuses = hasMany(
    FilterV2StatusRecord.self,
    using: ForeignKey([Columns.id], to: [FilterV2StatusRecord.Columns.filterId])
  )
  var statuses: QueryInterfaceRequest<FilterV2StatusRecord> {
    request(for: Self.statuses)
  }

  init(_ filter: FilterV2) {
    id = filter.id
    title = filter.title
    context = filter.context
    expiresAt = filter.expiresAt
    filterAction = filter.filterAction
  }
}

/// Persistence layer version of `Mastodon.FilterV2.Keyword`.
struct FilterV2KeywordRecord: ContentDatabaseRecord, Hashable {
  public let filterId: FilterV2.ID
  public let id: FilterV2.Keyword.ID
  public let keyword: String
  public let wholeWord: Bool

  enum Columns: String, ColumnExpression {
    case filterId
    case id
    case keyword
    case wholeWord
  }

  init(filterId: FilterV2.ID, _ filterKeyword: FilterV2.Keyword) {
    self.filterId = filterId
    id = filterKeyword.id
    keyword = filterKeyword.keyword
    wholeWord = filterKeyword.wholeWord
  }
}

/// Persistence layer version of `Mastodon.FilterV2.Status`.
struct FilterV2StatusRecord: ContentDatabaseRecord, Hashable {
  public let filterId: FilterV2.ID
  public let id: FilterV2.Status.ID
  public let statusId: Mastodon.Status.Id

  enum Columns: String, ColumnExpression {
    case filterId
    case id
    case statusId
  }

  init(filterId: FilterV2.ID, _ filterStatus: FilterV2.Status) {
    self.filterId = filterId
    id = filterStatus.id
    statusId = filterStatus.statusId
  }
}
