class User < ActiveRecord::Base
  include RoleModel
  
  roles :admin, :regular
  
  has_paper_trail
  
  has_magick_columns name: :string, lastname: :string, email: :email
  
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
    :validatable

  # Defaul order
  default_scope -> { order('lastname ASC') }
  
  # Validations
  validates :name, presence: true
  validates :name, :lastname, :email, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
  
  # Relaciones
  has_many :outflows
  
  def initialize(attributes = nil, options = {})
    super(attributes)
    
    self.role ||= :regular
  end
  
  def to_s
    [self.name, self.lastname].compact.join(' ')
  end
  
  def role
    self.roles.first.try(:to_sym)
  end
  
  def role=(role)
    self.roles = [role]
  end
  
  def self.filtered_list(query)
    query.present? ? magick_search(query) : all
  end
end
