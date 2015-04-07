namespace :send_reminders do
  desc "Sends Daily Reminders"
  task daily: :environment do

    Time.zone = ActiveSupport::TimeZone["Central Time (US & Canada)"]

    puts "[START] #{DateTime.now}"
    groups = Group.active
    puts "Sending Daily Reminders for events for today"
    for group in groups
      events = group.events.today.by_date
      if events.count > 0
        for group_user in group.group_users
          if group_user.daily_reminder == 1
            user = User.find(group_user.user_id)
            if (group_user.mine_only == 1)
              has_tickets = events.map { |e| e.user_has_ticket?(user) }
              next unless has_tickets.include?(true)
            end
            puts "- Sending #{user.display_name} (#{user.email}) for #{group.group_name}"
            ScheduleNotifier.daily_schedule(events, group, user).deliver
          end
        end
      else
        puts "- No events for #{group.group_name}"
      end
    end
    puts "Done!"
    puts "[END] #{DateTime.now}"
  end

  desc "Sends Weekly Reminders"
  task weekly: :environment do

    Time.zone = ActiveSupport::TimeZone["Central Time (US & Canada)"]

    puts "[START] #{DateTime.now}"
    groups = Group.active
    puts "Sending Weekly Reminders for events for next seven days"
    for group in groups
    events = group.events.next_seven_days.by_date
      if events.count > 0
        for group_user in group.group_users
          if group_user.weekly_reminder == 1
            user = User.find(group_user.user_id)
            if (group_user.mine_only == 1)
              has_tickets = events.map { |e| e.user_has_ticket?(user) }
              next unless has_tickets.include?(true)
            end
            puts "- Sending #{user.display_name} (#{user.email}) for #{group.group_name}"
            ScheduleNotifier.weekly_schedule(events, group, user).deliver
          end
        end
      else
        puts "- No events for #{group.group_name}"
      end
    end
    puts "Done!"
    puts "[END] #{DateTime.now}"
  end

end
