# Link Menus

## current state

When a link inside a `TouchFallthroughTextView` (used for status body and profile bio text) is long-pressed, it currently displays a highlight around the link, but does nothing else.

![example of current state](current-link-long-press.md "a grey box displayed around a long-pressed hashtag link")

## desired state

Instead of the grey box, we want to display a useful context menu.

### profile links

For links to profiles (marked with `HTML.LinkClass.mention`), the context menu should display a "View Profile" action, corresponding to the normal action when you tap the link, followed by the same actions as `ProfileViewController.menu`:

- share
- report
- block
- etc.

using the same logic as `ProfileViewController` to decide which to show. So that logic should be extracted for reuse.

### hashtag links

For links to hashtags (marked with `HTML.LinkClass.mention`), we want a "View Timeline" action to navigate to the hashtag timeline, corresponding to the normal action when you tap the link.

We want to be able to follow (if not following) or unfollow (if following) the hashtag. (If we don't have the follow state, don't show these menu actions). Logic for this already exists in `TagTimelineActionViewModel` and should be extracted for reuse.

We should also show a "Filter" or "Unfollow & Filter" menu action (depending on follow state). The user can use this action to ignore all posts with a given hashtag by creating a keyword filter with the full text of the hashtag, including the hash symbol.

### web links

For all other links, the top action should be "Open", same as the tap action. We should also include "Copy Link" and "Share" actions.

