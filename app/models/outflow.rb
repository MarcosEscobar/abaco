class Outflow < ActiveRecord::Base
  has_paper_trail
  
  # Constantes
  KIND = {
    upfront: 'u',
    to_favor: 'f',
    refunded: 'r',
    maintenance: 'm',
    purchase: 'p',
    payoff: 'x',
    other: 'o'
  }.with_indifferent_access.freeze
  
  # Scopes
  scope :upfronts, -> { where(kind: KIND[:upfront]) }
  scope :to_favor, -> { where(kind: KIND[:to_favor]) }
  scope :credits, -> { where(kind: [KIND[:upfront], KIND[:to_favor]]) }
  scope :of_operators, -> { not(where(operator_id: nil)) }
  scope :for_operator, -> (operator) { where(operator_id: operator) }
  
  # Attributos no persistentes
  attr_accessor :auto_operator_name
  
  # Validaciones
  validates :amount, :kind, :user_id, presence: true
  validates :amount, numericality: { allow_nil: true, allow_blank: true, 
    greater_than: 0.00 }
  validates :operator_id, presence: true, if: :operator_needed?
  validates :comment, presence: true, if: :kind_is_other?
  
  # Relaciones
  belongs_to :user

  KIND.each do |kind, value|
    define_method("kind_is_#{kind}?") { self.kind == KIND[kind] }
  end

  def operator_needed?
    self.kind_is_to_favor? || self.kind_is_upfront? || self.kind_is_payoff?
  end
  
  def kind_symbol
    KIND.invert[self.kind]
  end

  def self.operator_pay_pending_shifts_between(options = {})
    shifts = OperatorShifts.find(:all, params: { 
      user_id: options[:operator_id],
      pay_pending_shifts_for_user_between: {
        start: options[:start],
        finish: options[:finish]
      }
    })
    
    if shifts.size > 0
      start, finish = shifts.first.created_at, shifts.last.created_at
      worked_hours = worked_hours(shifts)
      to_pay = calculate_how_much_money_have_to_pay(
        worked_hours, options[:admin]
      )
      
      {
        hours: worked_hours,
        earns: to_pay,
        count: shifts.size,
        start: start,
        finish: finish
      }
    end
  end

  def refund!
    self.update_attributes(kind: KIND[:refunded])
  end
  
  def self.pay_operator_shifts_and_upfronts(options = {})
    Operator.find(options[:operator_id]).patch(
      :pay_shifts_between, start: options[:start], finish: options[:finish]
    )
    
    Outflow.credits.where(operator_id: options[:operator_id]).all?(&:refund!)

    pay = Outflow.create!(
      kind: KIND[:payoff],
      comment: [
        I18n.l(Date.parse(options[:start]), format: :long),
        I18n.l(Date.parse(options[:finish]), format: :long)
      ].join(' -> '),
      amount: options[:amount].to_f,
      user_id: options[:user_id],
      operator_id: options[:operator_id]
    )

    upfront = options[:upfronts].to_f
    
    if upfront != 0
      Outflow.create!(
        kind: (upfront < 0 ? KIND[:to_favor] : KIND[:upfront]),
        amount: upfront.abs,
        comment: I18n.t('view.outflows.reajust_of', outflow_id: pay.id),
        user_id: options[:user_id],
        operator_id: options[:operator_id]
      )
    else
      true
    end
  end

  def self.calculate_how_much_money_have_to_pay(hours, admin)
    admin = admin.to_bool if admin.kind_of? String
    operator_type = admin ? 
      'pay_per_administrator_hour' : 
      'pay_per_operator_hour'
    pay_per_hour = Setting.find_by_var(operator_type).value.to_f

    hours * pay_per_hour
  end

  def self.worked_hours(shifts)
    hours = 0
    shifts.map { |s| hours += s.finish.to_time - s.start.to_time } 

    hours / 3600
  end

  def operator_name
    begin
      Operator.find(self.operator_id).try(:label)
    rescue
      'Unknown'
    end
  end

  def self.credit_for_operator(operator)
    operator_outflows = Outflow.where(operator_id: operator)

    (
      operator_outflows.to_favor.sum(&:amount) -
      operator_outflows.upfronts.sum(&:amount)
    )
  end
end
