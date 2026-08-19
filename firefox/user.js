// Generated from theme/palette.toml by theme/sync-theme.py — do not edit.
//
// Firefox prefs as tracked text. Symlinked into the profile by bootstrap.sh.
//
// Firefox re-applies this file over prefs.js at every startup, so anything set
// here cannot drift: changing it in about:config lasts until the next restart.
// That is the point — prefs.js is mutable state, this is the source. Anything
// genuinely per-machine belongs in about:config, not here.

// Load-bearing. Without this, chrome/userChrome.css and chrome/userContent.css
// are ignored outright and the browser renders in stock colours.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Sidebery owns tab display. Firefox's own vertical tabs ship inside the
// "revamp" sidebar, which reparents the sidebar DOM and drops #sidebar-header —
// the node userChrome.css hides. Leaving revamp on means two competing tab
// strips and a chrome stylesheet that silently half-applies.
user_pref("sidebar.revamp", false);
user_pref("sidebar.verticalTabs", false);

// Paints the pre-render window and about:blank in the palette background.
// Without it every new tab flashes white before content paints.
user_pref("browser.display.background_color", "#1c1420");

user_pref("browser.uidensity", 1);
user_pref("browser.compactmode.show", true);

// Onboarding. These fire on a fresh profile and after every major update,
// which on a machine rebuilt from this repo is exactly when nobody wants them.
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("full-screen-api.warning.timeout", 0);

// Sponsored content on the new tab page and in the address bar.
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);

// Telemetry. policies.json sets DisableTelemetry, which covers the same ground
// from outside the profile; these hold on a profile whose policies.json was
// wiped by a Firefox upgrade before the next bootstrap run restores it.
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
