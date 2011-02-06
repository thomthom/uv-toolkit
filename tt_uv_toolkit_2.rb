#-----------------------------------------------------------------------------
# Compatible: SketchUp 6 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
#
# 2.2.0 - 23.01.2011
#		 * UV Memory stores backside
#		 * UV Memory cleans up UV data
#		 * UV Memory toolbar buttons
#		 * UV Memory fixes
#		 * UV Clipboard supports multiple copy
#		 * Extension support
#
# 2.1.0 - 06.01.2011
#		 * Experimental UV Memory
#
# 2.0.0 - 15.12.2010
#		 * Initial release.
#		 * UV Clipboard.
#		 * Fit Texture Material to Quad-Face - if no material selected, use the
#      material of the faces processed.
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

#-----------------------------------------------------------------------------

module TT
  module Plugins
    module UV_Toolkit
    
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION   = '2.2.0'.freeze
  PREF_KEY  = 'TT_UV_Toolkit2'.freeze
  TITLE     = 'UV Toolkit²'.freeze
  
  
  ### EXTENSION ### --------------------------------------------------------
  
  path = File.dirname( __FILE__ )
  loader = File.join( path, 'TT_UV_Toolkit', 'loader.rb' )
  ex = SketchupExtension.new( TITLE, loader )
  ex.version = VERSION
  ex.copyright = 'Thomas Thomassen © 2010—2011'
  ex.creator = 'Thomas Thomassen (thomas@thomthom.net)'
  ex.description = 'Suite of UV mapping tools.'
  Sketchup.register_extension( ex, true )
  
    end
  end
end # module


#-----------------------------------------------------------------------------
file_loaded( __FILE__ )
#-----------------------------------------------------------------------------