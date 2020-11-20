-- Copyright 2014-2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.cdefs.glib'

C, ffi_cast, ffi_string = ffi.C, ffi.cast, ffi.string
band = bit.band
gchar_arr = ffi.typeof 'gchar [?]'

effective_keyval = ffi.new 'guint [1]'
consumed_modifiers = ffi.new 'GdkModifierType [1]'

explain_key_code = (code, event) ->
  effective_code = code == 10 and Gdk.KEY_Return or code

  key_name = C.gdk_keyval_name effective_code
  if key_name != nil
    event.key_name = ffi_string(key_name)\lower!

  unicode_char = C.gdk_keyval_to_unicode code

  if unicode_char != 0
    utf8 = gchar_arr(6)
    nr_utf8 = C.g_unichar_to_utf8 unicode_char, utf8
    if nr_utf8 > 0
      event.character = ffi.string utf8, nr_utf8

  event.key_code = code

get_modifiers = (state) ->
  {
      shift: band(state, C.GDK_SHIFT_MASK) != 0,
      control: band(state, C.GDK_CONTROL_MASK) != 0,
      alt: band(state, C.GDK_MOD1_MASK) != 0,
      super: band(state, bit.bor(C.GDK_SUPER_MASK, C.GDK_MOD4_MASK)) != 0,
      meta: band(state, C.GDK_META_MASK) != 0,
      lock: band(state, C.GDK_LOCK_MASK) != 0,
  }

{
  parse_key_event: (key_event) ->
    key_event = ffi_cast('GdkEventKey *', key_event)

    keymap = C.gdk_keymap_get_for_display Gdk.display.get_default!
    C.gdk_keymap_translate_keyboard_state keymap, key_event.hardware_keycode, key_event.state, 0, effective_keyval, nil, nil, consumed_modifiers

    new_keyval = tonumber effective_keyval[0]
    event = get_modifiers key_event.state

    -- if keyval is different in "default" layout and event looks like shortcut,
    -- replace keyval and exclude consumed modifiers
    is_shortcut = event.control or event.alt or event.super or event.meta
    if new_keyval != key_event.keyval and is_shortcut
      not_modifiers = tonumber consumed_modifiers[0]
      -- return shift to modifiers
      not_modifiers = bit.band(not_modifiers, bit.bnot(C.GDK_SHIFT_MASK))
      event = get_modifiers band(key_event.state, bit.bnot(not_modifiers))
      explain_key_code new_keyval, event
    else
      explain_key_code key_event.keyval, event
    event.modifiers = key_event.state
    event

}
