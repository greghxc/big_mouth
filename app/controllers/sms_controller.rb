class SmsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def connect
    not_valid && return unless valid?

    @twilio_num = params['To']
    @sender = params['From']
    @orig_body = params['Body']

    t = TwilioNumber.find_by_number(@twilio_num)
    fail && return if t.blank? || !t.assigned

    @driver_num = t.reservation.driver_number.number
    @passeger_num = t.reservation.external_numbers.first.number

    fail && return unless params['retry'].blank?
    send_to_passenger && return if @driver_num == @sender
    send_to_driver && return if @passeger_num.include?(@sender)
    fail
  end

  private
  def valid?
    !params['To'].blank? && !params['From'].blank? && !params['Body'].blank?
  end

  def not_valid
    render text: 'invalid parameters'
  end

  def fail
    fail_msg = 'Sorry, no current reservation found. Please call 206-526-6087 for assistance.'
    send_msg(@sender, fail_msg)
    render text: fail_msg
  end

  def send_to_passenger
    send_msg(@passenger_num, @orig_body)
    render text: 'sent to passenger'
  end

  def send_to_driver
    send_msg(@driver_num, @orig_body)
    render text: 'sent to driver'
  end

  def send_msg(to, msg)
    @client = Twilio::REST::Client.new
    @client.messages.create(
        from: @twilio_num,
        to: to,
        body: msg
    )
  end

end