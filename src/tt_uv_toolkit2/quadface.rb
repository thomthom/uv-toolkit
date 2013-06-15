#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------


module TT::Plugins::UV_Toolkit
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( __FILE__ )     
    # Constants
    ROTATE90  = 1
    ROTATE180 = 2
    ROTATE270 = 3
    
    # Menus
    # (!) Use Command objects, for menu statusbar description.
    @menu.add_separator
    @menu.add_item('Fit Texture to Quad-faces') {
      self.fit_quad_faces
    }
    @menu.add_separator
    @menu.add_item('Rotate QF Texture Clockwise 90°') {
      self.rotate_quad(ROTATE90)
    }
    @menu.add_item('Rotate QF Texture Counter Clockwise 90°')  {
      self.rotate_quad(ROTATE270)
    }
    @menu.add_item('Rotate QF Texture 180°') {
      self.rotate_quad(ROTATE180)
    }
  end # UI
  file_loaded( __FILE__ )
  
  
  # Stretch the current material's texture across a quad-face.
  def self.fit_quad_faces
    model = Sketchup.active_model
    current_material = model.materials.current
    
    if current_material && current_material.texture.nil? then
      UI.messagebox 'Select a material with a texture. Can\'t UV map solid colours.'
      return
    end
    
    if current_material && !TT::Material.in_model?( current_material )
      UI.messagebox 'Select a material that exists in the model material list.'
      return
    end
    
    material = current_material
    task_name = 'Fit Texture to Quad-Faces'
    TT::SimpleTask.new( task_name, model.selection, model ).run { |e|
      next unless e.is_a?( Sketchup::Face )
      corners = TT::Face.corners( e )
      next unless corners.size == 4
      
      if current_material.nil?
        material = e.material if e.material.texture
      end
      next if material.nil?

      # (!) Sort points so that we begin with the edge closest to the
      # X axis on the lowest Z level. This will position the textures
      # more uniformly.
      
      # Position texture
      pts = []
      pts << corners[0].position
      pts << [0,0,0]
      
      pts << corners[1].position
      pts << [1,0,0]
      
      pts << corners[3].position
      pts << [0,1,0]
      
      pts << corners[2].position
      pts << [1,1,0]
      
      e.position_material(material, pts, true)
    }
  end
  
  
  # Rotates the texture of all the quad-faces in the selection.
  def self.rotate_quad(rotation)
    model = Sketchup.active_model
    
    return if model.selection.empty?

    tw = Sketchup.create_texture_writer
    task_name = 'Rotate Quad-Face Textures'
    TT::SimpleTask.new( task_name, model.selection, model ).run { |e|
      next unless e.is_a?( Sketchup::Face )
      next if e.material.nil? || e.material.texture.nil?
      self.rotate_texture_quad( e, rotation, tw )
    }
  end
  
  
  # Rotate the quad-face's texture by a given multiply of 90 degrees
  def self.rotate_texture_quad(face, rotation, texture_writer)
    return false unless face.is_a?( Sketchup::Face )
    
    uvh = face.get_UVHelper(true, false, texture_writer)
    
    # Arrays containing 3D and UV points.
    xyz = []
    uv = []
    
    # Get the quad-face corners.
    corners = TT::Face.corners( face )
    return false unless corners.size == 4
    
    # Get current UV-coordinates from the four corners.
    corners.each { |pt|
      uvq = uvh.get_front_UVQ(pt.position)
      xyz << pt.position
      uv << TT::UVQ.normalize(uvq)
    }
    
    # Shuffle the points so we 'rotate' the texture.
    (1..rotation).each {
      uv << uv.shift # Move first entry to the end. Effectivly rotates 90 degrees.
    }
    
    # Position texture.
    pts = []
    (0..3).each { |i|
      pts << xyz[i]
      pts << uv[i]
    }
    
    face.position_material(face.material, pts, true)
    return true
  end
  
end # module