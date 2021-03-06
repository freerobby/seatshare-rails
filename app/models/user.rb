##
# User model
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :tickets, dependent: :destroy, foreign_key: :owner_id
  has_many :user_aliases, dependent: :destroy
  has_many :memberships, dependent: :delete_all
  has_many :groups, through: :memberships, dependent: :destroy,
                    foreign_key: :creator_id

  before_save :clean_calendar_token

  validates :first_name, :last_name, :email, presence: true

  scope :by_name, (-> { order('LOWER(last_name) ASC, LOWER(first_name) ASC') })
  scope :active, (-> { where(status: true) })

  attr_accessor :entity_id
  attr_accessor :newsletter_signup
  attr_accessor :invite_code

  ##
  # Check if active for authentication
  def active_for_authentication?
    super && status?
  end

  ##
  # New user object
  # - attributes: attributes for object
  def initialize(attributes = {})
    attr_with_defaults = {
      status: true
    }.merge(attributes)
    super(attr_with_defaults)
  end

  ##
  # Display name for user
  def display_name
    "#{first_name} #{last_name}"
  end

  ##
  # Default gravatar based on email
  # - dimensions: string of avatar size in `NxN` format
  def gravatar(dimensions = '30x30')
    require 'digest/md5'
    email_address = email.downcase
    hash = Digest::MD5.hexdigest(email_address)
    "https://www.gravatar.com/avatar/#{hash}?s=#{dimensions}&d=mm"
  end

  ##
  # Format mobile phone number in `+11235551234` format
  def mobile_e164
    GlobalPhone.normalize(mobile)
  end

  ##
  # Bio as Markdown
  def bio_md
    renderer = Redcarpet::Render::HTML.new(filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true)
    markdown.render(bio || '')
  end

  ##
  # User Can View?
  # - user: instance of user to see if they have a common group
  def user_can_view?(user)
    return false if user.nil?
    return true if user.id == id
    shared_users = []
    groups.collect do |group|
      group.members.collect do |u|
        shared_users << u.id
      end
    end
    return true if shared_users.include? user.id
    false
  end

  ##
  # Destroy
  def destroy
    Ticket.where(user_id: id).find_each do |ticket|
      ticket.user_id = 0
      ticket.save!
    end
    super
  end

  private

  ##
  # Generate a unique calendar token
  def generate_calendar_token
    SecureRandom.urlsafe_base64(nil, false)
  end

  ##
  # Run calendar token generator if not set
  def clean_calendar_token
    self.calendar_token = generate_calendar_token if calendar_token.blank?
  end
end
