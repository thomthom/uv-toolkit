#-----------------------------------------------------------------------------
# Compatible: SketchUp 6 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
#
# 2.2.0 - 09.01.2011
#		 * UV Memory stores backside
#		 * UV Memory cleans up UV data
#		 * UV Memory toolbar buttons
#		 * UV Memory fixes
#		 * UV Clipboard supports multiple copy.
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

# (!) VALIDATE CURRENT MATERIAL!

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.5.0', 'UV Toolkit²')

#-----------------------------------------------------------------------------

module TT::Plugins::UV_Toolkit
  
  
  ### MODULE VARIABLES ### -------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    @menu = TT.menu('Plugins').add_submenu('UV Toolkit²')
    @toolbar = UI::Toolbar.new( 'UV Toolkit²' )
  
    require 'TT_UV_Toolkit/core.rb'
    require 'TT_UV_Toolkit/quadface.rb'
    require 'TT_UV_Toolkit/clipboard.rb'
    require 'TT_UV_Toolkit/memory.rb'

    # Restore Toolbar
    if @toolbar.get_last_state == TB_VISIBLE
      @toolbar.restore
      UI.start_timer( 0.1, false ) { @toolbar.restore } # SU bug 2902434
    end
  end
  
  
  ### DEBUG ### ------------------------------------------------------------
  
  def self.reload
    load __FILE__
    load 'TT_UV_Toolkit/core.rb'
    load 'TT_UV_Toolkit/quadface.rb'
    load 'TT_UV_Toolkit/clipboard.rb'
    load 'TT_UV_Toolkit/memory.rb'
  end
  
end # module


#-----------------------------------------------------------------------------
file_loaded( __FILE__ )
#-----------------------------------------------------------------------------