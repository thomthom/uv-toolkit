#-----------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
# 0.1.0b - xx.xx.2010
#		 * ...
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.4.0', 'TT UV Patch')

#-----------------------------------------------------------------------------

module TT::Plugins::UV_Patch
  
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION = '0.1.0'.freeze
  PREF_KEY = 'TT_UV_Patch'.freeze
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Resource paths
    #root_path = File.dirname( __FILE__ )
    #path = File.join( root_path, 'TT_UV_Patch' )
    
    # Commands
    #cmdAddUVPlane = UI::Command.new('Add UV Plane') { self.uv_map_plane }
    #cmdAddUVPlane.small_icon = File.join( path, 'Images', 'UV_16.png' )
    #cmdAddUVPlane.large_icon = File.join( path, 'Images', 'UV_24.png' )
    #cmdAddUVPlane.tooltip = 'Add UV Plane mapping.'
    #cmdAddUVPlane.status_bar_text = 'Add UV Plane mapping.'
    
    # Menus
    m = TT.menu('Tools').add_submenu('UV Patch')
    m.add_item('Map Test')     { self.map_patch }
    #m.add_item( cmdAddUVPlane )
    
    # Toolbar
    #toolbar = UI::Toolbar.new('UV Gizmo')
    #toolbar = toolbar.add_item( cmdAddUVPlane )
    #toolbar.show if toolbar.get_last_state == TB_VISIBLE
  end
  
  
  ### MAIN SCRIPT ### ------------------------------------------------------

  
  def self.map_patch
    model = Sketchup.active_model
    entities = model.selection.to_a
    
    types = self.categorize_entities( entities )
    #edges = types[ Sketchup::Edge ]
    faces = types[ Sketchup::Face ]
    edges = self.face_edges(faces)
    
    faces.each { |f| f.material = [192,128,128] }
    
    borders = self.find_borders( edges, faces )
    if borders
      clr = [
        [0,255,128],
        [128,255,0],
        [128,0,255],
        [255,0,128]
      ]
      borders.each_with_index { |edges,i|
        edges.each { |e|
          e.material = clr[i]
        }
      }
      puts "Border Groups: #{borders.size}"
    else
      puts "Fail!"
    end
  end
  
  
  class QuadFace
    
    def initialize(*args)
      # (!) Verify two faces are connected.
      raise( ArgumentError, 'Max two faces.') if args.size > 2
      if args.size == 1 && args[0].is_a?( Array )
        unless args[0].all? { |e| e.is_a?( Sketchup::Face) }
          raise( ArgumentError, 'Must be faces.')
        end
        @faces = args[0].dup
      elsif args.size == 2
        unless args.all? { |e| e.is_a?( Sketchup::Face) }
          raise( ArgumentError, 'Must be all faces.')
        end
        @faces = args.dup
      else
        raise( ArgumentError, 'Must be array or series of faces.')
      end
    end
    
    def loop
      if complex?
        face1 = faces.first
        face2 = faces.last
        joint = face1.edges & face2.edges
        (face1.edges + face2.edges) - joint
        # (!) sort
      else
        @faces.first.edges
      end
    end
    
    def complex?
      @faces.size == 2
    end
    
  end # class QuadFace
  
  
  # (!) TT_Lib2
  def self.categorize_entities(entities)
    categories = {}
    for e in entities
      categories[ e.class ] ||= []
      categories[ e.class ] << e
    end
    categories
  end
  
  
  def self.find_quadpatch(entities)
    types = self.categorize_entities( entities )
    faces = types[ Sketchup::Face ]
    edges = self.face_edges(faces)
    borders = self.find_borders( edges, faces )
    return nil unless borders.size == 4 # (!) Or 2 - in case of loop
    # (!) Sort faces
  end
  
  
  def self.face_edges(faces)
    edges = []
    for face in faces
      edges.concat( face.edges )
    end
    edges.uniq
  end
  
  
  # (!) Handle loop
  def self.find_borders(edges, faces)
    border_edges = edges.select { |e|
      (e.faces & faces).length == 1
    }
    #border_edges.each { |e| e.material = [255,128,0] }
    
    # (!) Find connected groups
    # 1 group = patch
    # 2 groups = loop
    # Anything else is invalid
    
    corner_faces = faces.select { |f|
      face_border_edges = f.edges & border_edges
      face_border_edges.length >= 2
    }
    corner_faces.each { |f| f.material = [128,64,64] }
    return nil unless corner_faces.size == 4
    
    corner_vertices = corner_faces.map { |f|
      be = f.edges & border_edges
      cv = self.face_corners(f)
      corner = cv.find { |v|
        (v.edges & be).size == 2
      }
      corner
    }
    #corner_vertices.each_with_index { |v,i|
    #  Sketchup.active_model.active_entities.add_text( i.to_s, v.position, [2,2,2] )
    #}
    
    # Start at one corner and start tracking the border.
    start_vertex = corner_vertices.first
    start_edge = (start_vertex.edges & border_edges).first
    
    vertices = [ start_vertex ]
    border = [ start_edge ]
    borders = []
    
    cache = border_edges - [start_edge]
    until cache.empty?
      # Find next edge in border loop.
      vertex = border.last.other_vertex( vertices.last )
      next_edge = ( (vertex.edges & border_edges) & cache ).first
      # Corner check.
      prev_edge = border.last
      if corner_vertices.include?( vertex )
        borders << border.dup
        border.clear
      end
      
      vertices << vertex
      border << next_edge
      cache.delete( next_edge )
    end
    borders << border.dup
    borders
  end
  
  
  # (!) Move to TT_Lib2
  def self.common_vertex(edge1, edge2)
    edge1.vertices.find { |v|
      v.edges.include?( edge2 )
    }
  end
  
  # Finds the corners in a face, ignoring vertices between colinear edges.
  # (!) Move to TT_Lib2
	def self.face_corners(face)
		corners = []
		# We only check the outer loop, ignoring interior lines.
		face.outer_loop.edgeuses.each { |eu|
			# Ignore vertices that's between co-linear edges. When using .same_direction?
      # we must test the vector in both directions.
			unless eu.edge.line[1].parallel?(eu.next.edge.line[1])
			#unless eu.edge.line[1].samedirection?(eu.next.edge.line[1]) ||
			#		eu.edge.line[1].reverse.samedirection?(eu.next.edge.line[1])
				# Find which vertex is shared between the two edges.
				if eu.edge.start.used_by?(eu.next.edge)
					corners << eu.edge.start
				else
					corners << eu.edge.end
				end
			end
		}
		return corners
	end

  
  def self.reload(clear_screen=false)
    cls if clear_screen
    load __FILE__
    TT::Lib.reload
    cls if clear_screen
  end
  
  
end # module

#-----------------------------------------------------------------------------
file_loaded( __FILE__ )
#-----------------------------------------------------------------------------