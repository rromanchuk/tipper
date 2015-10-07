User.all.items.each do |user|
  begin 
    puts User.update_user_with_twitter(user, true).to_yaml
  	sleep 4
  rescue 
	 puts "error"
	end
end