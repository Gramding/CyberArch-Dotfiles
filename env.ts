import GLib from "gi://GLib"
import GdkPixbuf from "gi://GdkPixbuf"
import Gtk from "gi://Gtk?version=3.0"
import Gdk from "gi://Gdk?version=3.0"


export const HOME = GLib.get_home_dir()
export const CYBER_DIR = `${HOME}/.config/hypr/themes/cyberpunk`
export const COMPONENTS_DIR = `${CYBER_DIR}/components`

// Locks, pid files and scratch images belong in the per-user runtime dir (0700, tmpfs, cleared on
// logout), not in /tmp. A predictable /tmp path lets any other local user pre-create it or point a
// symlink at it before we do.
export const RUNTIME_DIR = `${GLib.get_user_runtime_dir() || `${HOME}/.cache`}/cyberpunk`
// non-fatal: if this fails the individual writes below fail loudly on their own
try { GLib.mkdir_with_parents(RUNTIME_DIR, 0o700) } catch (e) { }
const display = Gdk.Display.get_default()!
const monitor = display.get_primary_monitor() ?? display.get_monitor(0)!
const geo = monitor.get_geometry()
export const SCREEN_WIDTH = geo.width
export const SCREEN_HEIGHT = geo.height
