require 'securerandom'
require 'digest'


def form_incomplete?
  [:username, :password, :email].each do |p|
    if params[p] == ""
      return true
    end
  end
  false
end

def username_taken?
  query = "SELECT * FROM users WHERE username = $1"
  result = PG.connect(dbname: 'trailview').exec_params(query, [params[:username]]).to_a
  if result.empty?
    return false
  else
    return true
  end
end


def valid_user?(username, password)
  query = "SELECT * FROM users WHERE username = $1"
  result = PG.connect(dbname: 'trailview').exec_params(query, [username]).to_a

  if result.empty?
    return false
  else
    salt = result[0]["salt"]
    password = Digest::SHA2.hexdigest(params[:password] + salt)
    if password == result[0]["password"]
      return true
    else
      return false
    end
  end
end

def create_user
  salt = SecureRandom.hex(30).to_s
  password = Digest::SHA2.hexdigest params[:password] + salt

  query = "INSERT INTO users (username, password, email, salt) values ($1,$2,$3,$4);"
  result = PG.connect(dbname: 'trailview').exec_params(query,[params[:username], password, params[:email],salt])

  id = get_user_id(params[:username])

  Dir.mkdir("public/UserPhotos/#{id}")

end

def get_user_id(username)
  query = "SELECT id FROM users WHERE username = $1"
  result = PG.connect(dbname: 'trailview').exec_params(query,[username]).to_a[0]["id"]
end

def set_user(id)
  session[:user_id] = id
end

def current_user
  id = session[:user_id]
end


def logged_in?
  if session[:user_id].nil?
    false
  else
    true
  end
end

def authenticate
  if !logged_in?
    redirect "/"
  end
end


def matches_owner?(owner_id)
  session[:user_id] != owner_id ? false : true
end
