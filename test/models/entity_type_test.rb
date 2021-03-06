require 'test_helper'

##
# Entity Type test
class EntityTypeTest < ActiveSupport::TestCase
  test 'display name matches' do
    entity_type = EntityType.find(1)

    assert_equal entity_type.display_name, 'National Hockey League (NHL)'
  end
  
  test 'has seatgeak url' do
    entity_type = EntityType.find(1)
    
    assert entity_type.seatgeek?
  end
end
