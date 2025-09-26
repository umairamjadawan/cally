#!/usr/bin/expect -f

# Direct deployment script using expect for password automation
set timeout 300
set server "157.230.142.228"
set password "0f65fbf94679333dff40877bef"

# Connect and deploy
spawn ssh root@$server

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "root@" {
        # Now we're connected, send the deployment commands
        send "apt update && apt upgrade -y\r"
        expect "root@"
        
        send "apt install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev nodejs npm nginx ufw expect\r"
        expect "root@"
        
        send "adduser cally --disabled-password --gecos \"\"\r"
        expect "root@"
        
        send "usermod -aG sudo cally\r"
        expect "root@"
        
        send "echo 'cally ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers\r"
        expect "root@"
        
        # Switch to cally user and continue setup
        send "su - cally\r"
        expect "cally@"
        
        # Install RVM
        send "curl -sSL https://get.rvm.io | bash\r"
        expect "cally@"
        
        send "source ~/.rvm/scripts/rvm\r"
        expect "cally@"
        
        send "rvm install ruby-3.4.1\r"
        expect "cally@"
        
        send "rvm use ruby-3.4.1@cally --create --default\r"
        expect "cally@"
        
        # Install Ollama
        send "curl -fsSL https://ollama.ai/install.sh | sh\r"
        expect "cally@"
        
        # Start Ollama
        send "nohup ollama serve > ~/ollama.log 2>&1 &\r"
        expect "cally@"
        
        send "sleep 15\r"
        expect "cally@"
        
        send "ollama pull phi3:mini\r"
        expect "cally@"
        
        # Clone Cally
        send "git clone https://github.com/umairamjadawan/cally.git\r"
        expect "cally@"
        
        send "cd cally\r"
        expect "cally@"
        
        # Setup Rails
        send "bundle install\r"
        expect "cally@"
        
        send "RAILS_ENV=production rails db:create db:migrate db:seed\r"
        expect "cally@"
        
        send "RAILS_ENV=production rails assets:precompile\r"
        expect "cally@"
        
        send "export SECRET_KEY_BASE=\\$(rails secret)\r"
        expect "cally@"
        
        send "echo \"export SECRET_KEY_BASE=\\$SECRET_KEY_BASE\" >> ~/.bashrc\r"
        expect "cally@"
        
        # Exit back to root
        send "exit\r"
        expect "root@"
        
        # Configure Nginx and services as root
        send "rm -f /etc/nginx/sites-enabled/default\r"
        expect "root@"
        
        # Create Nginx config
        send "cat > /etc/nginx/sites-available/cally << 'NGINX_EOF'\r"
        send "server {\r"
        send "    listen 80;\r"
        send "    server_name _;\r"
        send "    location / {\r"
        send "        proxy_pass http://localhost:3000;\r"
        send "        proxy_set_header Host \\$host;\r"
        send "        proxy_set_header X-Real-IP \\$remote_addr;\r"
        send "        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;\r"
        send "        proxy_set_header X-Forwarded-Proto \\$scheme;\r"
        send "    }\r"
        send "}\r"
        send "NGINX_EOF\r"
        expect "root@"
        
        send "ln -sf /etc/nginx/sites-available/cally /etc/nginx/sites-enabled/\r"
        expect "root@"
        
        send "systemctl restart nginx\r"
        expect "root@"
        
        # Start Cally directly
        send "su - cally -c 'cd cally && nohup RAILS_ENV=production rails server -b 0.0.0.0 -p 3000 > ~/cally.log 2>&1 &'\r"
        expect "root@"
        
        send "sleep 10\r"
        expect "root@"
        
        # Configure firewall
        send "ufw allow OpenSSH\r"
        expect "root@"
        
        send "ufw allow 'Nginx Full'\r" 
        expect "root@"
        
        send "ufw --force enable\r"
        expect "root@"
        
        # Final check
        send "curl -s http://localhost:3000/health\r"
        expect "root@"
        
        send "echo '🎉 Cally is now running at http://157.230.142.228'\r"
        expect "root@"
        
        send "exit\r"
    }
}

expect eof
