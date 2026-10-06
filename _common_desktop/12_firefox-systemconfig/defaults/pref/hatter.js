// Keep the audio stream open across seeks instead of tearing it down.
// Bluetooth headphones otherwise go to sleep on every seek and take ~1s to wake up.
// https://bugzilla.mozilla.org/show_bug.cgi?id=2059525
pref("media.audio.reuse-stream-on-seek", true);
