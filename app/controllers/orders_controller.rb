class OrdersController < ApplicationController
  before_action :current_order, only: [:cancel, :finished, :edit]
  before_action :validate_user, only: [:cancel, :finished]
  before_action :validate_can_edit, only: [:edit]

  def index
    @orders = current_user.orders.includes(:goods)
    @orders = @orders.order(created_at: :desc).page(params[:page] || 1).per(20)
  end

  def new
    @order = Order.new
  end

  def edit
    @order = Order.find(params[:id])
  end

  def create
    begin
      goods_id = params['order']['goods_id']
      count = params['order']['count']
      goods = Goods.find(goods_id)
      if goods.present?
        price_current = goods.get_current_price(current_user.level_id)
        total_price = price_current.to_i * count.to_i

        order =  current_user.orders.create(params.require(:order).permit(:goods_id, :count, :remark))

        order.price_current = price_current
        order.total_price = total_price

        notice = order.save ?  '订单创建成功，请点支付订单' : '订单创建失败，请稍后重试'
      else
        notice = ''
      end
    rescue => e
      notice = e.message
    end
    redirect_to :back, notice: notice
  end

  def update
    #begin
      @order = Order.find(params[:id])
      goods = Goods.find(params[:order][:goods_id])
      count = params[:order][:count]
      if @order.is_paied?
        attritutes = params.require(:order).permit(:remark)
        @order.update_attributes(attritutes)
      else
        remark = params[:order][:remark]
        price_current = goods.get_current_price(current_user.level_id)
        total_price = price_current.to_i * count.to_i

        @order.update_attributes(goods_id: goods.id, price_current: price_current, count: count, total_price: total_price, remark: remark)
      end
      notice = '订单修改完成'
    #rescue
      notice = '订单修改失败'
    #end

    redirect_to action: 'index', notice: notice
  end

  def cancel
    # begin
      if @order.can_cancel?
        @order.update_attribute(:status, 'Canceled')
        notice = '订单已取消'
      else
        notice = '订单取消失败, 当前订单不可取消'
      end
    # rescue
      notice = '订单取消失败，请刷新页面后重试'
    # end

    redirect_to :back, notice: notice
  end

  def finished
    begin
      if @order.can_make_finished?
        @order.update_attribute(:status, 'Finished')
        notice = '订单已完成'
      else
        notice = '当前订单状态不能变更为以完成'
      end
    rescue
      notice = '变更状态失败，请刷新页面后重试'
    end

    redirect_to :back, notice: notice
  end

  private
  def current_order
    @order = Order.find(params['id'])
  end

  def validate_user
    return redirect_to :back, notice: '权限错误！' if @order.user_id != current_user.id
  end

  def validate_can_edit
    return redirect_to :back, notice: '当前订单不可以修改！' if !@order.can_edit?
  end
end