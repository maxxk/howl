-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.container'

C = ffi.C

core.define 'GtkBin < GtkContainer', {
  get_child: => C.gtk_bin_get_child @
}
