##
# User Alias model
class UserAlias < ActiveRecord::Base
  belongs_to :user

  validates :first_name, :last_name, :user_id, presence: true

  scope :by_name, (-> { order('LOWER(last_name) ASC, LOWER(first_name) ASC') })

  ##
  # Display name for user alias
  def display_name
    "#{first_name} #{last_name}"
  end

  ##
  # Handle ticket unassignment on delete
  def destroy
    Ticket.where(alias_id: id).find_each do |ticket|
      ticket.alias_id = 0
      ticket.save!
    end
    super
  end
end
