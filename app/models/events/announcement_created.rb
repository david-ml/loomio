class Events::AnnouncementCreated < Event
  include Events::Notify::InApp
  include Events::Notify::ByEmail

  def self.bulk_publish!(model, actor, memberships, kind)
    Array(memberships).map do |membership|
      build(model,
        user: actor,
        custom_fields: { membership_id: membership.id, kind: kind }
      )
    end.tap do |events|
      import events
      events.map(&:trigger!)
    end
  end

  def membership
    @membership ||= Membership.find(custom_fields['membership_id'])
  end

  private

  def email_users!
    return unless Queries::UsersByVolumeQuery.normal_or_loud(eventable).include?(membership.user)
    eventable.send(:mailer).delay.send(custom_fields['kind'], membership.user, self)
  end

  def notification_recipients
    User.where(id: membership.user_id)
  end
end