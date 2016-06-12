require 'net/telnet'

#注意，$prompt是登陆侯的命令提示行，如果匹配不上，脚本将会timeout
username = 'sunjunior';
password = 'xxxx';
port = 23;
prompt = /[$%#>] \z/n
hostlist = ['127.0.0.1']
login_prompt =  /[Ll]ogin[: ]*\z/n 
password_prompt = /[Pp]ass(?:word|phrase)[: ]*\z/n

hostlist.each {
  |host|  host.gsub!(/\s+/, '')
  session = Net::Telnet.new(
  "Host" => host,
  "Port" => port,
  "Timeout" => 30,
  "Prompt" => prompt
  ) {
    |c| print c
  }
  
  session.login("Name" => username,
    "Password" => password,
    "LoginPrompt" => login_prompt,
    "PasswordPrompt" => password_prompt) {
      |c| print c
    }
    
  session.cmd('ls -l')  {
    |c| print c
  }
}