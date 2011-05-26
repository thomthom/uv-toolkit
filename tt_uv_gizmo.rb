#-------------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-------------------------------------------------------------------------------
#
# CHANGELOG
# 0.1.0b - xx.xx.2010
#		 * ...
#
#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.4.0', 'TT UV Gizmo')

#-------------------------------------------------------------------------------

module TT::Plugins::UV_Gizmo
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  VERSION = '0.1.0'.freeze
  
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( File.basename(__FILE__) )
    # Resource paths
    root_path = File.dirname( __FILE__ )
    path = File.join( root_path, 'TT_UV_Tools' )
    
    # Commands
    cmdAddUVPlane = UI::Command.new('Add UV Plane') { self.uv_map_plane }
    cmdAddUVPlane.small_icon = File.join( path, 'Images', 'UV_16.png' )
    cmdAddUVPlane.large_icon = File.join( path, 'Images', 'UV_24.png' )
    cmdAddUVPlane.tooltip = 'Add UV Plane mapping.'
    cmdAddUVPlane.status_bar_text = 'Add UV Plane mapping.'
    
    # Menus
    m = TT.menu('Tools').add_submenu('UV Gizmo')
    m.add_item('Project Test')     { self.project_texture }
    m.add_item( cmdAddUVPlane )
    
    # Toolbar
    toolbar = UI::Toolbar.new('UV Gizmo')
    toolbar = toolbar.add_item( cmdAddUVPlane )
    toolbar.show if toolbar.get_last_state == TB_VISIBLE
  end
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------

  
  def self.project_texture
    model = Sketchup.active_model
    ents = model.active_entities
    sel = model.selection
    
    model.start_operation('Project UV')
    
    uvp = TT::UV_Plane.new( [10,10,0], Y_AXIS.reverse, model.materials.current )
    
    sel.each { |face|
      uvp.project( face, true )
    }
    
    model.commit_operation
  end
  
  
  def self.uv_map_plane
    model = Sketchup.active_model
    material = model.materials.current
    return if material.nil? || material.texture.nil?
    model.tools.push_tool( T_UV_Gizmo_Plane.new(material) )
  end  
  
  
  class T_UV_Gizmo_Plane
    
    def initialize(material)
      Sketchup.active_model.start_operation( 'UV Map' )
      
      @material = material
      @width  = @material.texture.width
      @height = @material.texture.height
      
      origin = TT::Selection.bounds.center
      @plane = TT::UV_Plane.new( origin, Y_AXIS.reverse, @material )
      @plane.center = origin
      
      @selected = false
      
      update_gizmo()
      
      axes = @plane.normal.axes
      @manipulator = TT::Gizmo::Manipulator.new( origin, axes.x, axes.y, axes.z )
    end
    
    def activate
      Sketchup.active_model.active_view.invalidate
    end
    
    def deactivate(view)
      view.model.commit_operation
      view.invalidate
    end
    
    def resume(view)
      view.invalidate
    end
    
    def onLButtonDown(flags, x, y, view)
      #puts 'MASTER DOWN'
      #p @plane.origin
      #p @plane.normal
      
      @manipulator.onLButtonDown(flags, x, y, view)
      view.invalidate
    end
    
    def onLButtonUp(flags, x, y, view)
      #puts 'MASTER UP'
      #p @plane.origin
      #p @plane.normal
      
      @manipulator.onLButtonUp(flags, x, y, view)
      #@plane.origin = @manipulator.origin
      #@plane.normal = @manipulator.normal
      
      #puts 'project....'
      @plane.project_to_entities( view.model.selection.to_a )
      view.invalidate
    end
    
    def onMouseMove(flags, x, y, view)
      ph = view.pick_helper
      #@selected = ph.pick_segment(@frame, x, y)
      
      @manipulator.onMouseMove(flags, x, y, view)
      if flags & MK_LBUTTON == MK_LBUTTON
        @plane.center = @manipulator.origin
        @plane.normal = @manipulator.normal
        update_gizmo()
        @plane.project_to_entities( view.model.selection.to_a )
      end
      
      view.invalidate
    end
    
    def draw(view)
      view.line_stipple = ''
      view.line_width = 2
      
      # Plane
      view.drawing_color = 'orange'
      view.draw( GL_LINE_STRIP, @frame )
      view.drawing_color = Sketchup::Color.new(255,128,0,64)
      view.draw( GL_QUADS, @frame[0..3] )
      
      # Plane orientation indicator
      pts = []
      p1 = @frame[2]
      p2 = @frame[3]
      pts << Geom::Point3d.linear_combination( 0.5, p1, 0.5, p2 )
      pts << pts.last.offset( @plane.normal.axes.y, view.pixels_to_model(20, pts.last) )
      view.draw( GL_LINES, pts )
      
      # Selection
      view.line_width = 6
      view.drawing_color = 'blue'
      sel = get_selected_segment()
      view.draw( GL_LINES, sel ) unless sel.nil?
      
      # Manipulator
      @manipulator.draw( view )
    end
    
    def update_gizmo
      #origin, normal = @plane.to_a
      
      #width  = @width / 2.0
      #height = @height / 2.0
      #o = origin.offset( normal.axes.x.reverse, width )
      #o.offset!( normal.axes.y.reverse, height )
      
      #@frame = []
      #@frame << o
      #@frame << @frame.last.offset(normal.axes.x, @width)
      #@frame << @frame.last.offset(normal.axes.y, @height)
      #@frame << @frame.first.offset(normal.axes.y, @height)
      #@frame << o
      
      @frame = @plane.frame_segments
    end
    
    def get_selected_segment
      return nil if @selected.is_a?(FalseClass)
      if @selected < 0
        i = @selected.abs - 1
      else
        i = @selected
      end
      @frame[ i, 2 ]
    end
    
  end # class T_UV_Gizmo_Plane
  
  
  # TT::Plugins::UV_Gizmo.reload
  def self.reload( tt_lib = false, clear_screen=false )
    cls if clear_screen
    load __FILE__
    TT::Lib.reload if tt_lib
    cls if clear_screen
  end
  
  
end # module

#-------------------------------------------------------------------------------
file_loaded( File.basename(__FILE__) )
#-------------------------------------------------------------------------------