class Order < ApplicationRecord
  validates :count, presence: true
  validates :price_current, presence: true
  validates :total_price, presence: true
  validates :status, presence: true

  belongs_to :user
  belongs_to :goods

  after_create :add_identification_code

  after_update :update_user_level
  #生成订单编号
  def add_identification_code
    id_str = self.id.to_s
    len = 6 - id_str.length
    id_code =  self.created_at.to_i.to_s + '0'*len + id_str
    self.update_attribute(:identification_code, id_code)
  end

  def is_not_pay?
    self.status == 'Waiting'
  end

  def is_paied?
    self.status == 'Paied'
  end

  def is_canceled?
    self.status == 'Canceled'
  end

  def is_finished?
    self.status == 'Finished'
  end

  def can_cancel?
    self.status == 'Waiting'
  end

  def can_make_finished?
    self.status == 'Paied'
  end

  def can_edit?
    status == 'Paied' || status == 'Waiting'
  end

  def status_in_word
    case status
    when 'Waiting'
      '等待支付'
    when 'Paied'
      '已支付，等待处理'
    when 'Canceled'
      '已取消'
    when 'Finished'
      '已完成'
    when 'dealing'
      '商家已接单，处理中'
    end
  end

  def status_in_word_admin
    case status
    when 'Paied'
      '用户已经支付，等待你的待处理'
    when 'Dealing'
      '用户已经支付，你标记状态为处理中'
    when 'Waiting'
      '用户未支付'
    when 'Finished'
      '已完成订单，可点击隐藏订单'
    when 'Refunding'
      '用户申请退款'
    when 'Refunded'
      '已经退款'
    end
  end

  def update_user_level
    if status_changed? && status == 'Finished' && user.level_id < 4
      tar_user = self.user
      total_spend = tar_user.total_spend
      current_level_id = tar_user.level_id
      next_level = Level.find(current_level_id + 1)

      tar_user.update_attribute(:level_id, next_level.id) if total_spend >= next_level.price
    end
  end
end
