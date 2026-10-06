# Settings content

Edit `settings.json` to change the Settings page title, section titles, row labels, and row order. Each row's `id` selects its action in `SettingsPage`; keep existing IDs when changing labels. The `icon` field uses an alias defined by `SettingsPage`.

Edit `widget_tutorial.json` to change tutorial tabs, step instructions, images, and the optional note at the end of each tab. Each step has an `images` array; add one or two entries in display order. To replace a placeholder, add an image asset to the project and set that image's `asset` to its Flutter asset path. Set `aspectRatio` to the image width divided by its height. Leave `asset` as `null` to keep the placeholder. Set a tab's `note` to `null` to hide its note.

These JSON files are bundled with the app. Changes appear in the next app build; they are not writable user storage or a remote content feed.
