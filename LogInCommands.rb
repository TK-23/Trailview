def validate_user(username, password)
  query = "SELECT user_id FROM users WHERE username LIKE $1 AND password LIKE $2"
  result = PG.connect(dbname: 'trailview').exec_params(query, [username, password]).to_a
  if result.empty?
    return nil
  else
    result.first["user_id"]
  end
end

def authorized?
  session[:user_id] == nil ? false : true
end
