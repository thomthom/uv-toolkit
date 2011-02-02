#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#
# EXPERIMENTAL! MANY UNRESOLVED ISSUES!
#
#-----------------------------------------------------------------------------


module TT::Plugins::UV_Toolkit

  UV_ATTR_ID = 'TT::UV::Memory'.freeze
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( __FILE__ )      
    cmdRememberUV = UI::Command.new('Remember UV') {
      self.remember_uv
    }
    cmdRememberUV.large_icon = 'Images/uv_store_24.png'
    cmdRememberUV.small_icon = 'Images/uv_store_16.png'
    cmdRememberUV.status_bar_text = 'Save the selected faces\' UV data with the face.'
    cmdRememberUV.tooltip = 'Save the selected faces\' UV data with the face.'
    
    cmdRestoreUV = UI::Command.new('Restore UV') {
      self.restore_uv
    }
    cmdRestoreUV.large_icon = 'Images/uv_restore_24.png'
    cmdRestoreUV.small_icon = 'Images/uv_restore_16.png'
    cmdRestoreUV.status_bar_text = 'Restore the selected faces\' UV data face.'
    cmdRestoreUV.tooltip = 'Restore the selected faces\' UV data face.'
    
    # Menu
    @menu.add_separator
    @menu.add_item( cmdRememberUV )
		@menu.add_item( cmdRestoreUV )
    
    # Toolbar
    @toolbar.add_separator
    @toolbar.add_item( cmdRememberUV )
    @toolbar.add_item( cmdRestoreUV )
  end # UI
  file_loaded( __FILE__ )
  
  
  # Store the UV data for the vertices of tri and quad-faces in the selection.
  # Since each vertex might connect to multiple faces, an ID is given to the
  # face. That ID is used to find the correct UV data for the given vertex.
  def self.remember_uv
    model = Sketchup.active_model
    tw = Sketchup.create_texture_writer
    
    TT::SimpleTask.new( 'Remember UV', model.selection, model ).run { |e|
      next unless e.is_a?( Sketchup::Face )
      
      front_valid = e.material && e.material.texture
      back_valid = e.back_material && e.back_material.texture      
      next unless front_valid || back_valid
      
      corners = TT::Face.corners( e )
      
      # entityID is not persistant, so there might be a chance of setting
      # the same ID to two faces? (probably small, but can a more reliable ID
      # be used?)
      #face_id = e.entityID
      face_id = "#{e.entityID}#{Time.now.to_f}"#.hash.to_s
      e.set_attribute( UV_ATTR_ID, 'id', face_id )
      
      uvh = e.get_UVHelper( front_valid, back_valid, tw )
      corners.each { |v|
        self.cleanup_uv_data( v )
        if front_valid
          uvq = uvh.get_front_UVQ( v.position )
          uv = TT::UVQ.normalize( uvq )
          v.set_attribute( UV_ATTR_ID, face_id, uv.to_a )
        end
        if back_valid
          uvq = uvh.get_back_UVQ( v.position )
          uv = TT::UVQ.normalize( uvq )
          v.set_attribute( UV_ATTR_ID, "#{face_id}_back", uv.to_a )
        end
      }
    }
  end
  
	def self.restore_uv
    model = Sketchup.active_model
    
    TT::SimpleTask.new( 'Restore UV', model.selection, model ).run { |e|
      next unless e.is_a?(Sketchup::Face)
      
      front_valid = e.material && e.material.texture
      back_valid = e.back_material && e.back_material.texture
      next unless front_valid || back_valid
      
      corners = TT::Face.corners(e)
      next unless [3,4].include?( corners.size )
      
      face_id = e.get_attribute( UV_ATTR_ID, 'id' )
      next if face_id.nil?
      
      pts_front = []
      pts_back  = []
      corners.each { |v|
        self.cleanup_uv_data( v )
        if front_valid
          uv = v.get_attribute( UV_ATTR_ID, face_id )
          unless uv.nil?
            pts_front << v.position
            pts_front << uv
          end
        end
        if back_valid
          uv = v.get_attribute( UV_ATTR_ID, "#{face_id}_back" )
          unless uv.nil?
            pts_back << v.position
            pts_back << uv
          end
        end
      }
      # Validate the number of points retreived.
      # Since the geometry might have changed it's possible that the stored
      # UV data is no longer valid and that the face vertices doesn't all
      # have UV data attached.
      if front_valid && pts_front.size == corners.size * 2
        e.position_material(e.material, pts_front, true)
      end
      if back_valid && pts_back.size == corners.size * 2
        e.position_material(e.material, pts_back, false)
      end
    }
  end
  
  # Validate each existing UV attribute and remove any which have no
  # connected face matching the ID.
  # (!) Check for multiple connected faces with the same id.
  def self.cleanup_uv_data( vertex )
    uv_data = vertex.attribute_dictionary( UV_ATTR_ID )
    return nil if uv_data.nil?
    uv_data.keys.to_a.each { |key|
      if result = key.match( /^(\d)_back$/ )
        face_id = result[1]
      else
        face_id = key
      end
      if vertex.faces.all? { |f| f.get_attribute( UV_ATTR_ID, 'id' ) == face_id }
        uv_data.delete_key( key )
      end
    }
    nil
  end
  
end # module