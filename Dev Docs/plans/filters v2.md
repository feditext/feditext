# filters v2

We're missing most filter v2 UI.

We've been operating with a slightly broken version of filters v2 on the instance types that support it (Mastodon 4 and up, GoToSocial 0.16 and up). v2 filters are checked on the server when retrieving statuses from a timeline. When the v2 filter action is `hide`, the status is not included in the retrieved timeline segment at all. When the action is `warn`, the status is included and has an attached `filtered` property containing a list of filter names explaining why it should not be shown, and Feditext's UI shows the names only unless the user decides to view the filtered status.

The issue with this is that we need to invalidate all timelines when v2 filters change for it to work, so that we get up to date timeline segments. We're not yet doing this. We don't even store v2 filters natively.

As a convenience feature, we want to have a v2 filter (the "quick status filter") that's automatically created by Feditext with a given name, which stores all filtered statuses added or removed by Feditext. This is so the user doesn't have to pick a filter every time they filter a status. This should hide the status in all filter contexts, and never expires.

With v2 filters, we no longer need to distinguish between active and expired filters on the client side. We just fetch what the server tells us.

## design concerns

The quick status filter doesn't let the user control which filter contexts to hide a status in. Maybe we should let them set that in preferences somewhere.

The user might want to add a filtered status to a filter that expires, or only applies to some contexts. Maybe we should show them options for non-quick filtering.

## plan

This is a good example of adding a medium-sized feature that requires changes from API through UI layers.

- Mastodon package
  - [x] Add v2 filter structs (in Filter.swift)
  - [x] Add `blur` filter action (specific to Mastodon, may not be supported by GoToSocial yet)
- MastodonAPI package
  - [x] Add FiltersV2Endpoint.filters to get all v2 filters
  - [x] Add EmptyEndpoint.deleteFilter, .deleteFilterKeyword, .deleteFilterStatus to delete v2 filters and their components
  - [x] Add FilterV2Endpoint.get to retrieve a single v2 filter
    - We might not actually need this outside of integration tests
  - [x] Add FilterV2Endpoint.create to create and retrieve a new v2 filter
  - [ ] Add FilterV2Endpoint.update to update and retrieve an existing v2 filter (change name, filter action, filter context, expiration time)
  - [ ] Add FilterV2KeywordEndpoint.create to create and retrieve a filter keyword attached to a filter
  - [ ] Add FilterV2KeywordEndpoint.update to change the keyword or the "whole word" matching flag
  - [x] Add FilterV2StatusEndpoint.create to create and retrieve a filter status attached to a filter
  - [x] Add StatusesEndpoint.statuses to get a list of statuses given a list of status IDs
- DB package
  - [x] Create persistence objects for FilterV2, FilterV2.Keyword, FilterV2.Status API structs
    - [x] FilterV2Info for retrieving a v2 filter joined to its keywords and statuses
    - [x] FilterV2Record, FilterV2KeywordRecord, FilterV2StatusRecord for storing and retrieving individual components of a filter
    - [x] Extensions to convert Info/Record structs to and from their API equivalents
  - [x] Create tables in new content database migration for storing v2 filters, keywords, statuses
    - We want these to be separate tables so that it's possible to join status filters to the statuses they're filtering. This enables showing a list of filtered statuses in case the user wants to stop filtering one.
  - [ ] Add methods for create, delete, update filter v2 operations to ContentDatabase
  - [ ] Add methods for create, delete, update filter v2 keyword operations to ContentDatabase
  - [ ] Add methods for create, delete filter v2 status operations to ContentDatabase
  - [x] Add v2 filter publisher allFilterV2sPublisher to ContentDatabase so higher layers can get notified when persisted filters change
  - [x] Add Identity.quickStatusFilter to store the name of the quick status filter in persistent user preferences
  - [ ] Document exactly what ContentDatabase.cleanHomeTimelinePublisher does and why
    - It seems to delete all timelines, statuses, and accounts if useHomeTimelineLastReadId is off, and preserve some accounts and statuses when useHomeTimelineLastReadId is on
    - We would use this to remove all timelines whenever v2 filters change
    - [ ] Figure out if we need to refetch the statuses that remain when useHomeTimelineLastReadId is on, so that they'll have correct filter properties
    - [ ] Create unit tests codifying behavior in both cases
  - [ ] Filter v2 create, update, delete operations in ContentDatabase should invoke cleanHomeTimelinePublisher to invalidate all timelines
- Services package
  - [x] Add FilteredStatusService as a new CollectionService
    - This collects all of the user's v2 filters, combines all of their filtered status IDs, and fetches them using StatusesEndpoint.statuses
    - [ ] Fix the FIXME: what should we do here? Should filtered statuses get saved to the content DB?
    - [ ] Could we use the persisted v2 filters and not have to make an API call to get them?
  - [x] Add NavigationService.filteredStatusesService to navigate to FilteredStatusService
  - StatusService
    - [ ] Add StatusService.filter so we can add a status to the quick status filter
      - [ ] Create a filter status
      - [ ] Add it to the quick status filter by calling the API and then the content DB add filter status method
      - [ ] Special case this and its dependencies so we can efficiently filter a single status without having to invalidate all timelines?
    - [ ] Add StatusService.unfilter so that we can remove a status from all of the user's filters
      - [ ] Look at all existing filtered statuses, and delete any that match our status ID from their parent filters, using the API and content DB
      - [ ] Likewise, it might make sense to special case unfiltering a single status
      - [ ] When editing a filter, we want to *instead* add it to the filter editing view model's list of filter statuses to delete when the filter is saved. This might require extending StatusService?
    - [ ] Add StatusService.canUnfilter: if the status has a `filtered` property and the status's ID is in that filter reasons list, this should be true and we should show UI for unfiltering the status
  - [x] Add APICapabilities.supportsV2Filters extension so we have a single convenient check for whether a backend server supports v2 filters
  - IdentityService
    - [x] In refreshFilters, if the backend server supports v2 filters, refresh those instead of v1 filters
    - [x] Add allFilterV2sPublisher() passing thru ContentDatabase.allFilterV2sPublisher
    - [ ] Add createFilterV2, updateFilterV2, deleteFilterV2, createFilterV2Keyword, updateFilterV2Keyword, deleteFilterV2Keyword, createFilterV2Status, deleteFilterV2Status using MastodonAPI filter v2 endpoints and their corresponding ContentDatabase methods
- ViewModels package
  - FilterV2sViewModel
    - [ ] Duplicate from FilterViewModel, including the split between active and expired filters
    - [ ] Add `delete(_ filterV2: FilterV2)` method
    - [ ] Move the part of FiltersView that lets the user set the quick status filter name in their preferences to this view model
  - EditFilterV2ViewModel
    - [ ] Create this view model to allow editing a single v2 filter
    - [ ] Similar to EditFilterViewModel
    - [ ] Add `create(_ filterKeyword: FilterV2.Keyword)`, which adds a new filter keyword using the placeholder ID `Filter.newFilterId`
    - Creating a new `FilterV2.Status` doesn't make sense because the user would need to know the status ID, so we won't do that here; they can instead filter statuses from the timeline views
    - [ ] Add `delete(_ filterKeyword: FilterV2.Keyword)` method which adds the deleted `filterKeyword.id` to the set `deletedFilterKeywordIDs` and removes `filterKeyword` from `filter.keywords` 
    - [ ] Add `delete(_ filterStatus: FilterV2.Status)` method which adds the deleted `filterStatus.id` to the set `deletedFilterStatusIDs` and removes `filterStatus` from `filter.statuses` 
    - [ ] `isSaveDisabled` methods will need to check the following:
      - [ ] Filter title not empty
      - [ ] Filter action selected
      - [ ] At least one filter context selected
      - [ ] For each filter keyword:
        - [ ] Filter keyword not empty
    - [ ] `save()` method:
      - [ ] if the filter is new, creates it and obtains the filter ID
      - [ ] otherwise, updates it and uses the existing filter ID
      - [ ] if there are new filter keywords, create them
      - [ ] update all other filter keywords
      - [ ] delete all filter keyword IDs in deletedFilterKeywordIDs
      - [ ] delete all filter status IDs in deletedFilterStatusIDs
  - AttachmentsRenderingViewModel
    - [x] add `blurReason: String?` with default extension implementation `{ nil }`
  - StatusViewModel
    - [ ] if the parent status is filtered with a `blur` filter action, set `blurReason` to the filter names joined with commas
    - [ ] modify `shouldShowAttachments` to add `blurReason != nil` alongside `!sensitive` as a reason to not show a blurred status's attachments initially 
- UI
  - FilterV2sView
    - [ ] Copy from FiltersView
    - [ ] Navigation link to FilteredStatusService in a TableViewController for the quick status filter. Unfiltering a status in this list unfilters it immediately.
    - [ ] Dropdown allowing the user to select which of the existing filters should become the quick status filter
  - EditFilterV2View
    - [ ] Field for title
    - [ ] Dropdown for filter action
    - [ ] List of toggles for filter contexts
      - see EditFilterView for this
    - [ ] Field for expiration date
      - [ ] Button to clear expiration date 
    - [ ] List of filter keywords
      - [ ] swipe to delete
      - [ ] button to add new row
      - each row should have:
        - [ ] field for keyword
        - [ ] toggle for "whole word" mode
    - [ ] Navigation link to a FilteredStatusService in a TableViewController, but with the property that unfiltering a status on this list does not actually unfilter it through the API, it just calls EditFilterV2ViewModel.delete(). See note about extending StatusService to support this.
  - AttachmentsView
    - [x] if `viewModel.blurReason` exists, set the title of `curtainButton` to the blur reason, taking priority over other things that would set the title (sensitive content, media hidden)

# alternate implementation

We could continue to apply all filters on the client side, as we already do with v1 filters. This would not be forwards-compatible if server-side filtering gets more complicated, but v1 filters do work fine.
