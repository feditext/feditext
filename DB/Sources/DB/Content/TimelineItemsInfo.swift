// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineItemsInfo: Codable, Hashable, FetchableRecord {
  let timelineRecord: TimelineRecord
  let statusInfos: [StatusInfo]
  let pinnedStatusesInfo: PinnedStatusesInfo?
  let loadMoreRecords: [LoadMoreRecord]
}

extension TimelineItemsInfo {
  struct PinnedStatusesInfo: Codable, Hashable, FetchableRecord {
    let accountRecord: AccountRecord
    let pinnedStatusInfos: [StatusInfo]
  }

  static func addingIncludes<T: DerivableRequest>(
    _ request: T,
    _ filterContext: Filter.Context?,
    ordered: Bool
  ) -> T where T.RowDecoder == TimelineRecord {
    let statusesAssociation = ordered ? TimelineRecord.orderedStatuses : TimelineRecord.statuses

    return
      request
      .including(all: StatusInfo.addingIncludes(statusesAssociation, filterContext).forKey(CodingKeys.statusInfos))
      .including(all: TimelineRecord.loadMores.forKey(CodingKeys.loadMoreRecords))
      .including(
        optional: PinnedStatusesInfo.addingIncludes(TimelineRecord.account)
          .forKey(CodingKeys.pinnedStatusesInfo))
  }

  static func request(
    _ request: QueryInterfaceRequest<TimelineRecord>,
    _ filterContext: Filter.Context?,
    ordered: Bool
  ) -> QueryInterfaceRequest<Self> {
    addingIncludes(request, filterContext, ordered: ordered).asRequest(of: self)
  }

  /// - SeeAlso: ``ContextItemsInfo``
  func items(_ matchers: [Filter.Matcher], _ displayFilter: DisplayFilter, now: Date) -> [CollectionSection] {
    let timeline = Timeline(record: timelineRecord)!
    var timelineItems =
      statusInfos
      .filtered(matchers, timeline.filterContext, now: now)
      .map {
        CollectionItem.status(
          .init(info: $0),
          .init(
            showContentToggled: $0.showContentToggled,
            showAttachmentsToggled: $0.showAttachmentsToggled,
            showFilteredToggled: $0.showFilteredToggled,
            isReplyOutOfContext: ($0.reblogInfo?.record ?? $0.record).inReplyToId != nil
          ),
          authorRelationship: $0.reblogInfo?.relationship ?? $0.relationship,
          rebloggerRelationship: $0.relationship
        )
      }
      .filter(displayFilter.allow)

    for loadMoreRecord in loadMoreRecords {
      guard
        let index = timelineItems.firstIndex(where: {
          guard case .status(let status, _, _, _) = $0 else { return false }

          return loadMoreRecord.afterStatusId > status.id
        })
      else { continue }

      timelineItems.insert(
        .loadMore(
          LoadMore(
            timeline: timeline,
            afterStatusId: loadMoreRecord.afterStatusId,
            beforeStatusId: loadMoreRecord.beforeStatusId
          )
        ),
        at: index
      )
    }

    let mainTimelineSection = CollectionSection(items: timelineItems)
    if timelineRecord.profileCollection == .statuses,
      let pinnedStatusInfos = pinnedStatusesInfo?.pinnedStatusInfos
    {
      let pinsSection = CollectionSection(
        items:
          pinnedStatusInfos
          .filtered(matchers, timeline.filterContext, now: now)
          .map {
            CollectionItem.status(
              .init(info: $0),
              .init(
                showContentToggled: $0.showContentToggled,
                showAttachmentsToggled: $0.showAttachmentsToggled,
                showFilteredToggled: $0.showFilteredToggled,
                isPinned: true,
                isReplyOutOfContext: ($0.reblogInfo?.record ?? $0.record).inReplyToId != nil
              ),
              authorRelationship: $0.reblogInfo?.relationship ?? $0.relationship,
              rebloggerRelationship: $0.relationship
            )
          }
          .filter(displayFilter.allow)
      )
      return [pinsSection, mainTimelineSection]
    } else {
      return [mainTimelineSection]
    }
  }
}

extension TimelineItemsInfo.PinnedStatusesInfo {
  static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
    request.including(
      all: StatusInfo.addingIncludes(AccountRecord.pinnedStatuses, .account)
        .forKey(CodingKeys.pinnedStatusInfos))
  }
}
