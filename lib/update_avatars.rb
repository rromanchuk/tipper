User.find_active.items.each do |user|
  puts User.update_user_with_twitter(user).to_yaml
  sleep 4
end