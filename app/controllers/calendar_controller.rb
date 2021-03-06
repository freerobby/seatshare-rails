##
# Calendar Controller
class CalendarController < ApplicationController
  before_action :authenticate_user!, except: %i[full group]
  layout 'two-column'

  ##
  # Calendar Instructions
  def index
    @token = current_user.calendar_token
    @groups = current_user.groups.active
  end

  ##
  # Complete Feed
  def full
    user = User.find_by(calendar_token: params[:token])
    show_404 unless user
    groups = user.groups

    # Create calendar object
    cal = Icalendar::Calendar.new
    cal.append_custom_property 'name', 'SeatShare'
    cal.timezone do |t|
      tz = user ? user.timezone : nil
      if tz.blank?
        t.tzid = Time.zone.tzinfo.name
      else
        t.tzid = ActiveSupport::TimeZone.create(user.timezone).tzinfo.name
      end
    end

    # Loop through the events
    groups.each do |group|
      group.events.each do |group_event|
        next if group_event.date_tba? == true
        cal.add_event(
          group_event.to_ics(
            url_for(
              controller: 'events', action: 'show',
              id: group_event.id, group_id: group.id
            )
          )
        )
      end
    end

    respond_to do |format|
      format.ics do
        cal.publish
        response.headers['Content-Disposition'] = 'attachment; '\
          'filename="seatshare.ics"'
        render text: cal.to_ical
      end
    end
  end

  ##
  # Group Feed
  def group
    user = User.find_by(calendar_token: params[:token])
    show_404 unless user
    group = Group.find(params[:group_id]) || show_404
    raise 'NotGroupMember' unless group.member?(user)

    # Create calendar object
    cal = Icalendar::Calendar.new
    cal.append_custom_property 'name', group.group_name
    cal.timezone do |t|
      tz = user ? user.timezone : nil
      if tz.blank?
        t.tzid = Time.zone.tzinfo.name
      else
        t.tzid = ActiveSupport::TimeZone.create(user.timezone).tzinfo.name
      end
    end

    # Loop through the events
    group.events.confirmed.each do |group_event|
      cal.add_event(
        group_event.to_ics(
          url_for(
            controller: 'events', action: 'show',
            id: group_event.id, group_id: group.id
          )
        )
      )
    end

    respond_to do |format|
      format.ics do
        cal.publish
        response.headers['Content-Disposition'] = 'attachment;'\
          " filename=\"seatshare_#{group.group_name.parameterize}.ics\""
        render text: cal.to_ical
      end
    end
  end
end
